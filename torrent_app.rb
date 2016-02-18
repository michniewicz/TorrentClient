require_relative 'lib/ruby-bencode/lib/bencode.rb'
# require all the files from lib and /lib/helpers/ directory
Dir['./lib/*.rb'].each {|file| require file }
Dir['./lib/helpers/*.rb'].each {|file| require file }

include ThreadHelper

torrent_file = ARGV[0] # read terminal param

TorrentService.new(torrent_file).start
ThreadHelper::join_thread_list
