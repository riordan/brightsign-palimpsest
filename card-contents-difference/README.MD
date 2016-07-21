This is an exploration in seeing the differences in an SD Card from when a brightsign is "Configures" through to the point when it downloads a presentation.

There are three folders in this directory:
- `card-setup` - the initial SDCard image from the setup
- `presentation-publish` - The presentation contents published to the HTTP server
- `card-contents` - Contents of the card at a given state. Initial commit should be identical to `card-setup` folder. Second commit should be the contents of the card after it has connected to the network and downloaded a show.

This uses (its own) master 1-video show as the contents of the presentation, located in the root of this project.
