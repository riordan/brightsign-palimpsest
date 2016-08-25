Library "setupCommon.brs"
Library "setupNetworkDiagnostics.brs"

Sub Main()

    ' Local setup script
    version="7.0.0.1"
    print "localSetup.brs version ";version;" started"

    modelSupportsWifi = GetModelSupportsWifi()

	CheckFirmwareVersion()

	' Load up the sync specification
	localToStandaloneSyncSpec = false
	setup_sync = CreateObject("roSyncSpec")
	if not setup_sync.ReadFromFile("setup.xml") then
		print "### No local sync state available"
		if not setup_sync.ReadFromFile("localSetupToStandalone-sync.xml") stop
		localToStandaloneSyncSpec = true
	endif

	lwsConfig$ = setup_sync.LookupMetadata("client", "lwsConfig")
    if lwsConfig$ = "content" then
		CheckStorageDeviceIsWritable()
	endif

    registrySection = CreateObject("roRegistrySection", "networking")
    if type(registrySection)<>"roRegistrySection" then print "Error: Unable to create roRegistrySection":stop

	ClearRegistryKeys(registrySection)
    
	' retrieve and parse featureMinRevs.xml
	featureMinRevs = ParseFeatureMinRevs()

	timezone$ = setup_sync.LookupMetadata("client", "timezone")
	unitName$ = setup_sync.LookupMetadata("client", "unitName")
	unitNamingMethod$ = setup_sync.LookupMetadata("client", "unitNamingMethod")
	unitDescription$ = setup_sync.LookupMetadata("client", "unitDescription")
	configVersion$ = setup_sync.LookupMetadata("client", "configVersion")
    
    ' write identifying data to registry
    registrySection.Write("tz", timezone$)
    registrySection.Write("un", unitName$)
    registrySection.Write("unm", unitNamingMethod$)
    registrySection.Write("ud", unitDescription$)
	
	if Len(configVersion$) > 0 then
		registrySection.Write("cfv", configVersion$)
	end if

	' network host parameters
	proxySpec$ = GetProxy(setup_sync, registrySection)
	bypassProxyHosts = GetBypassProxyHosts(proxySpec$, setup_sync)	

	timeServer$ = setup_sync.LookupMetadata("client", "timeServer")
	registrySection.Write("ts", timeServer$)
	print "time server in setup.brs = ";timeServer$

' Hostname
	SetHostname(setup_sync)

' Wireless parameters
	useWireless = SetWirelessParameters(setup_sync, registrySection, modelSupportsWifi)

' Wired parameters
	SetWiredParameters(setup_sync, registrySection, useWireless)

' Network configurations
	if setup_sync.LookupMetadata("client", "useWireless") = "yes"
		if modelSupportsWifi then
			wifiNetworkingParameters = SetNetworkConfiguration(setup_sync, registrySection, "", "")
			ethernetNetworkingParameters = SetNetworkConfiguration(setup_sync, registrySection, "_2", "2")
		else
			' if the user specified wireless but the system doesn't support it, use the parameters specified for wired (the secondary parameters)
			ethernetNetworkingParameters = SetNetworkConfiguration(setup_sync, registrySection, "_2", "")
		endif
	else
		ethernetNetworkingParameters = SetNetworkConfiguration(setup_sync, registrySection, "", "")
	endif

' Network connection priorities
	networkConnectionPriorityWired$ = GetEntry(setup_sync, "networkConnectionPriorityWired")
	networkConnectionPriorityWireless$ = GetEntry(setup_sync, "networkConnectionPriorityWireless")

' configure ethernet
	ConfigureEthernet(ethernetNetworkingParameters, networkConnectionPriorityWired$, timeServer$, proxySpec$, bypassProxyHosts, featureMinRevs)

' configure wifi if specified and device supports wifi
	if useWireless = "yes" then
		ssid$ = setup_sync.LookupMetadata("client", "ssid")
		passphrase$ = setup_sync.LookupMetadata("client", "passphrase")
		ConfigureWifi(wifiNetworkingParameters, ssid$, passphrase$, networkConnectionPriorityWireless$, timeServer$, proxySpec$, bypassProxyHosts, featureMinRevs)
	endif

' if a device is setup to not use wireless, ensure that wireless is not used (for wireless model only)
	if useWireless = "no" and modelSupportsWifi then
		DisableWireless()
	endif

' set the time zone
    if timezone$ <> "" then
        systemTime = CreateObject("roSystemTime")
        systemTime.SetTimeZone(timezone$)
        systemTime = invalid
    endif
        
' diagnostic web server
	SetDWS(setup_sync, registrySection)

' channel scanning data
	SetupTunerData()

' usb content update password
	usbUpdatePassphrase$ = GetEntry(setup_sync, "usbUpdatePassword")
	if usbUpdatePassphrase$ = "" then
		registrySection.Delete("uup")
	else
        registrySection.Write("uup", usbUpdatePassphrase$)
	endif

' local web server
	SetLWS(setup_sync, registrySection)

' logging
	SetLogging(setup_sync, registrySection)

' remote snapshot
	SetRemoteSnapshot(setup_sync, registrySection)

' idle screen color
	SetIdleColor(setup_sync, registrySection)

' custom splash screen
	SetCustomSplashScreen(setup_sync, registrySection, featureMinRevs)

' clear uploadlogs handler
    registrySection.Write("ul", "")
    
    registrySection.Flush()

' perform network diagnostics if enabled
	networkDiagnosticsEnabled = GetBooleanSpecEntry(setup_sync, "networkDiagnosticsEnabled")
	testEthernetEnabled = GetBooleanSpecEntry(setup_sync, "testEthernetEnabled")
	testWirelessEnabled = GetBooleanSpecEntry(setup_sync, "testWirelessEnabled")
	testInternetEnabled = GetBooleanSpecEntry(setup_sync, "testInternetEnabled")

	if networkDiagnosticsEnabled then
		PerformNetworkDiagnostics(testEthernetEnabled, testWirelessEnabled, testInternetEnabled)
	endif

' setup complete - wrap it up

    videoMode = CreateObject("roVideoMode")
    resX = videoMode.GetResX()
    resY = videoMode.GetResY()
    videoMode = invalid

    if lwsConfig$ = "content" then

        MoveFile("pending-autorun.brs", "autorun.brs")

		r=CreateObject("roRectangle",0,resY/2-resY/32,resX,resY/32)
		twParams = CreateObject("roAssociativeArray")
		twParams.LineCount = 1
		twParams.TextMode = 2
		twParams.Rotation = 0
		twParams.Alignment = 1
		tw=CreateObject("roTextWidget",r,1,2,twParams)
		tw.PushString("Local File Networking Setup is complete")
		tw.Show()

		r2=CreateObject("roRectangle",0,resY/2,resX,resY/32)
		tw2=CreateObject("roTextWidget",r2,1,2,twParams)
		tw2.PushString("The device will be ready for content downloads after it completes rebooting")
		tw2.Show()

		Sleep(30000)

        ' reboot
        a=RebootSystem()
        stop
        
	else if localToStandaloneSyncSpec then

        MoveFile("pending-autorun.brs", "autorun.brs")
		RestartScript()

    else

        r=CreateObject("roRectangle",0,resY/2-resY/64,resX,resY/32)
        twParams = CreateObject("roAssociativeArray")
        twParams.LineCount = 1
        twParams.TextMode = 2
        twParams.Rotation = 0
        twParams.Alignment = 1
        tw=CreateObject("roTextWidget",r,1,2,twParams)
        tw.PushString("Standalone Setup is complete - you may now remove the card")
        tw.Show()

        msgPort = CreateObject("roMessagePort")
        
        while true
            wait(0, msgPort)
        end while

    endif
    
End Sub


Function GetBooleanSpecEntry(spec As Object, elementName$ As String) As Boolean

	metadata$ = spec.LookupMetadata("client", elementName$ )
	if lcase(metadata$) = "true" then
		return true
	else
		return false
	endif

End Function

