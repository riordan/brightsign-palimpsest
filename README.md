Brightsign Palimpsest
======================

Investigating what came before and beneath the Brightsign presentation framework.

This project is an investigation of Brightsign's Presentation framework, used
by many systems prior to the creation of the HTML5 compatible models for syncing
a large number of displays.

We're going to hopefully use this to reverse engineer the brightsign framework
traditionally used via "Simple File Network" mode. Ideally this will result
in a library for authoring automatic Brightsign presentations from Javascript or
Python.


# Findings:
Using the kiddie-pool tool (soon to be renamed lifeguard (for ruling the /pool/))

Modifications have been made so it works on a `current-sync.xml` file.

```xml
<files>
  <download>
    <name>autoplay-39-video.xml</name>
    <hash method="SHA1">dc9b06092aa6191062dc2cf8a22356ac1d78f1d3</hash>
    <size>12073</size>
    <link>http://gurley-private.brown.columbia.edu/screen/39/pool/d/3/sha1-dc9b06092aa6191062dc2cf8a22356ac1d78f1d3</link>
    <headers inherit="no" />
    <chargeable>no</chargeable>
  </download>
  <delete>
    <pattern>*.brs</pattern>
  </delete>
  <delete>
    <pattern>*.rok</pattern>
  </delete>
  <delete>
    <pattern>*.bsfw</pattern>
  </delete>
  <ignore>
    <pattern>*</pattern>
  </ignore>
</files>

```

This means the only things you write are `<download>` objects. They're the only things to move in and out of the pool
