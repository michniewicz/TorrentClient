Bencode
=============
Bencode library written in Ruby language <br>

Bencoding is a way to specify and organize data in a terse format. It supports the following types:
byte strings, integers, lists, and dictionaries.<br>

Examples:
```
Bencode::Encoder.encode({ encoding: 'UTF-8', path: "1.png" })
 => 'd8:encoding5:UTF-84:path5:1.pnge'
```
```
Bencode::Decoder.decode('d3:bar4:spam3:fooi42ee')
 => { 'bar' => 'spam', 'foo' => 42 }
```

More about Bencoding:<br>
https://wiki.theory.org/BitTorrentSpecification#Bencoding