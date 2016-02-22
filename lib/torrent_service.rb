require_relative 'helpers/network_helper'

class TorrentService
  include NetworkHelper

  HANDSHAKE_TIMEOUT = 5 # Connection handshake timeout in sec

  def initialize(torrent_file)
    @meta_info = parse_meta_info(File.open(torrent_file))
    @client_id = generate_client_id # fake uTorrent client for now;)

    set_peers

    @message_queue = Queue.new
    @incoming_queue = Queue.new

    @scheduler = Scheduler.new(@peers, @meta_info)
    @file_loader = FileLoader.new(@meta_info)
  end

  # start torrent client lifecycle
  def start
    Thread::abort_on_exception = true #TODO delete it
    @peers.each { |peer| peer.perform(@message_queue) }

    run_lambda_in_thread(scheduler)
    run_lambda_in_thread(incoming_message)
    run_lambda_in_thread(file_loader)
  end

  # generate random peer_id in Azureus-style
  # see https://wiki.theory.org/BitTorrentSpecification#peer_id for reference
  def generate_client_id
    id = rand(1e11...1e12).to_i
    "-UT3130-#{id}"
  end

  private

  # parse metainfo from given torrent file
  # @param [String] torrent_file
  def parse_meta_info(torrent_file)
    MetaInfo.new(BEncode::Parser.new(torrent_file).parse!)
  end

  # lambda for Scheduler object
  def scheduler
    -> { run(@scheduler.request_queue, nil, RequestHandler.new) }
  end

  # lambda for Message objects from array of messages
  def incoming_message
    -> { run(@message_queue, @incoming_queue, MessageHandler.new(@meta_info.piece_length)) }
  end

  # lambda for FileLoader object
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
      message = input.pop
      break unless message
      if output
        handlers.each { |handler| handler.process(message, output) }
      else
        handlers.each { |handler| handler.process(message) }
      end
    end
  end

  # tracker params to send to uri defined in the torrent file -- @meta_info.announce
  # TODO add params to set not fully (non 100%) downloaded files and continue downloading
  def tracker_params
    { info_hash:  @meta_info.info_hash,
      peer_id:    @client_id,
      port:       '6881',
      uploaded:   '0',
      downloaded: '0',
      left:       @meta_info.total_size, # partial download after pause/interrupt is currently not supported
      compact:    '1',
      no_peer_id: '0',
      event:      'started' }
  end

  ######## peers methods ##########

  def set_peers
    @peers = Array.new
    # peers: (binary model) the peers value is a string consisting of multiples of 6 bytes.
    req = NetworkHelper::get_request(@meta_info.announce, tracker_params)
    peers = BEncode.load(req)['peers'].scan(/.{6}/)

    unpack_ports(peers).each do |host, port|
      add_peer(host, port)
    end
  end

  def add_peer(host, port)
    begin
      # handshake: <pstrlen><pstr><reserved><info_hash><peer_id>
      # In version 1.0 of the BitTorrent protocol, pstrlen = 19 (x13 hex), and pstr = "BitTorrent protocol".
      # reserved: eight (8) reserved bytes. All current implementations use all zeroes.
      handshake = "\x13BitTorrent protocol\x00\x00\x00\x00\x00\x00\x00\x00#{@meta_info.info_hash}#{@client_id}"
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
    peers.map {|p| p.unpack('a4n') }
  end

  #################################
end
