##
# Represents TorrentService class and its methods
#
class TorrentService
  include NetworkHelper

  # Connection handshake timeout in sec
  HANDSHAKE_TIMEOUT = 5

  def initialize(torrent_file)
    @torrent_file = torrent_file
    @files_to_load = []
    @message_queue = Queue.new
    @incoming_queue = Queue.new
    @meta_info = parse_meta_info(File.open(@torrent_file))
    @stop = false
    @file_loader = nil
  end

  # parse meta info and set all variables that depend on that info
  def init!
    # just warn for now
    PrettyLog.error('not enough free space') unless free_space_available?

    @file_loader = FileLoader.new(@meta_info)

    if @file_loader.content_exists?
      @file_loader.restore_data
    end
  end

  # start torrent client lifecycle
  def start
    init!

    if @file_loader.completed?
      PrettyLog.error('100%...seeding is still not implemented -- exit')
      return
    end

    request_peers
    @scheduler = Scheduler.new(@peers, @meta_info)
    launch_processes
  end

  # stop downloading (currently unsafe)
  def stop!
    # check @file_loader loader was already initialized with data
    if @file_loader
      bytes = @file_loader.downloaded_bytes
      params = TrackerInfo.tracker_params(@meta_info, bytes, :stopped)
      NetworkHelper.get_request(@meta_info.announce, params)
    end
    PrettyLog.error(' ----- stop! method called -----')
    @stop = true
    ThreadHelper.exit_threads
  end

  # returns list of files described in metainfo
  # @return [Array] files
  def get_files_list
    @meta_info.files
  end

  # set files selected for downloading
  def set_priorities(files)
    @files_to_load = files
    # TODO call this before start download
  end

  private

  def launch_processes
    # TODO delete it when stable
    Thread.abort_on_exception = true
    @peers.each { |peer| peer.perform(@message_queue) }

    run_lambda_in_thread(request_handler)
    run_lambda_in_thread(incoming_message)
    run_lambda_in_thread(file_loader)
  end

  # parse metainfo from given torrent file
  # @param [String] torrent_file
  def parse_meta_info(torrent_file)
    MetaInfo.new(BEncode.load_file(torrent_file))
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
  def run(input, output = nil, *handlers)
    loop do
      # check to avoid race condition on threads exit in stop! method
      break if @stop
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

  # set tracker params and set peers
  def request_peers
    bytes_so_far = @file_loader.downloaded_bytes
    params = TrackerInfo.tracker_params(@meta_info, bytes_so_far, :started)

    set_peers(params)
  end

  # performs request and unpacks peers host/port
  def set_peers(params)
    @peers = []
    # peers: (binary model) the peers value is a string
    # consisting of multiples of 6 bytes.
    req = NetworkHelper.get_request(@meta_info.announce, params)
    # split string per each 6 bytes
    peers = BEncode.load(req)['peers'].scan(/.{6}/)

    unpack_ports(peers).each do |host, port|
      add_peer(host, port)
    end
  end

  # handshake: <pstrlen><pstr><reserved><info_hash><peer_id>
  # In version 1.0 of the BitTorrent protocol,
  # pstrlen = 19 (x13 hex), and
  # pstr = "BitTorrent protocol".
  # reserved: eight (8) reserved bytes.
  # All current implementations use all zeroes.
  def add_peer(host, port)
    begin
      pstrlen = "\x13"
      pstr = 'BitTorrent protocol'
      reserved = "\x00\x00\x00\x00\x00\x00\x00\x00"
      handshake = "#{pstrlen}#{pstr}#{reserved}#{@meta_info.info_hash}#{TrackerInfo::CLIENT_ID}"
      Timeout.timeout(HANDSHAKE_TIMEOUT) { @peers << Peer.new(host, port, handshake, @meta_info.info_hash) }
    rescue => exception
      PrettyLog.error("#{__FILE__}:#{__LINE__} #{exception}")
    end
  end

  def unpack_ports(peers)
    # first 4 bytes of each peer are the IP address
    # and last 2 bytes are the port number.
    # All in network (big endian) notation
    # no need to unpack host, it will be passed as a network byte
    # ordered string to IPAddr::ntop
    # result example: ["\xBC\x92\a\xA3", 6881]  for single peer array
    peers.map { |p| p.unpack('a4n') }
  end

  #################################

  # checks if there is enough space on the hard drive
  # @return true if available
  def free_space_available?
    info = StatVFS.new.info
    free_bytes = info['f_bfree'] * info['f_bsize']
    return free_bytes > @meta_info.total_size
  end
end
