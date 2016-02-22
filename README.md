TorrentClient
=============

A BitTorrent client written in Ruby language. Developed as a part of Torrent server on Ruby on Rails

Currently implemented functionality:<br>
Downloading single and multiple files with torrent

TODO list:<br>
implement seeding;<br>
implement partial download;<br>
implement pause/resume;

Using as a standalone app:<br>
To download a file using TorrentClient, run the following from the root directory:

```
ruby torrent_app.rb <path/to/torrent_file> 
```

Using as a part of rails app: <br>
put the project into lib directory of rails application<br>
add this to your application.rb file
```
config.autoload_paths += %W(#{config.root}/lib)
require './lib/TorrentClient/torrent_lib'
```

More about Bittorrent Protocol Specification:<br>
https://wiki.theory.org/BitTorrentSpecification
https://en.wikipedia.org/wiki/Glossary_of_BitTorrent_terms