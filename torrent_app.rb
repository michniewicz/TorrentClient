# file with dependencies
require_relative 'torrent_lib'

include ThreadHelper

torrent_file = ARGV[0] # read terminal param

TorrentService.new(torrent_file).start
ThreadHelper::join_thread_list
