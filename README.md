TorrentClient
=============

A BitTorrent client written in Ruby language. Developed as a part of Torrent server on Ruby on Rails

Currently implemented functionality:<br>
Downloading single and multiple files with torrent

TODO list:<br>
implement seeding;<br>
implement partial download;<br>
implement pause/resume;

Run from terminal
----
To download a file using TorrentClient, run the following from the root directory:

```
ruby torrent_app.rb <path/to/torrent_file> 
```
More about Bittorrent Protocol Specification:
https://wiki.theory.org/BitTorrentSpecification
https://en.wikipedia.org/wiki/Glossary_of_BitTorrent_terms