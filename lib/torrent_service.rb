require_relative 'helpers/network_helper'

class TorrentService
  include NetworkHelper

  HANDSHAKE_TIMEOUT = 5 # Connection handshake timeout in sec

  def initialize(torrent_file)
    @torrent_file = torrent_file

    @message_queue = Queue.new
    @incoming_queue = Queue.new

    @stop = false
  end

  # parse meta info and set all variables that depend on that info
  def init!
    @meta_info = parse_meta_info(File.open(@torrent_file))
    set_peers
    @scheduler = Scheduler.new(@peers, @meta_info)
    @file_loader = FileLoader.new(@meta_info)
  end

  # start torrent client lifecycle
  def start
    init!

    Thread.abort_on_exception = true # TODO delete it
    @peers.each { |peer| peer.perform(@message_queue) }

    run_lambda_in_thread(request_handler)
    run_lambda_in_thread(incoming_message)
    run_lambda_in_thread(file_loader)
  end

  # stop downloading (currently unsafe)
  def stop!
    params = TrackerInfo.tracker_params(@meta_info, @file_loader.downloaded_bytes, :stopped)
    NetworkHelper.get_request(@meta_info.announce, params)
    PrettyLog.error(' ----- stop! method called -----')
    @stop = true
    ThreadHelper.exit_threads
  end

  private

  # parse metainfo from given torrent file
  # @param [String] torrent_file
  def parse_meta_info(torrent_file)
    MetaInfo.new(BEncode::Parser.new(torrent_file).parse!)
  end

  # lambda for RequestHandler object
  def request_handler
    -> { run(@scheduler.request_queue, nil, RequestHandler.new) }
  end

  # lambda for Message objects from array of messages
  def incoming_message
    -> { run(@message_queue, @incoming_queue, MessageHandler.new(@meta_info.piece_length)) }
  end

  # lambda for FileLoader and Scheduler objects
  def file_loader
    -> { run(@incoming_queue, nil, @file_loader, @scheduler) }
  end

  # run lambda block in a separate Thread
  # @param [lambda] lambda_
  def run_lambda_in_thread(lambda_)
    Thread.new { lambda_.call }
  end

  # runs loop and listens for messages if messages exist in input queue
  # @param [Queue] input
  # @param [Queue] output
  # @param [Array] handlers
  def run(input, output=nil, *handlers)
    loop do
      break if @stop # we need this check to avoid race condition on threads exit in stop! method
      message = input.pop
      break unless message
      if output
        handlers.each { |handler| handler.process(message, output) }
      else
        handlers.each { |handler| handler.process(message) }
      end
    end
  end

  ######## peers methods ##########

  def set_peers
    @peers = []
    # peers: (binary model) the peers value is a string consisting of multiples of 6 bytes.
    params = TrackerInfo.tracker_params(@meta_info, 0, :started)
    req = NetworkHelper.get_request(@meta_info.announce, params)
    peers = BEncode.load(req)['peers'].scan(/.{6}/) # split string per each 6 bytes

    unpack_ports(peers).each do |host, port|
      add_peer(host, port)
    end
  end

  def add_peer(host, port)
    begin
      # handshake: <pstrlen><pstr><reserved><info_hash><peer_id>
      # In version 1.0 of the BitTorrent protocol, pstrlen = 19 (x13 hex), and pstr = "BitTorrent protocol".
      # reserved: eight (8) reserved bytes. All current implementations use all zeroes.
      handshake = "\x13BitTorrent protocol\x00\x00\x00\x00\x00\x00\x00\x00#{@meta_info.info_hash}#{TrackerInfo::CLIENT_ID}"
      Timeout::timeout(HANDSHAKE_TIMEOUT) { @peers << Peer.new(host, port, handshake, @meta_info.info_hash) }
    rescue => exception
      PrettyLog.error("#{__FILE__}:#{__LINE__} #{exception}")
    end
  end

  def unpack_ports(peers)
    # first 4 bytes of each peer are the IP address and last 2 bytes are the port number.
    # All in network (big endian) notation
    # no need to unpack host, it will be passed as a network byte ordered string to IPAddr::ntop
    # result example: ["\xBC\x92\a\xA3", 6881]  for single peer array
    peers.map { |p| p.unpack('a4n') }
  end

  #################################
end
