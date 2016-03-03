class Message
  # define all messages in the protocol
  MESSAGES = { '-1' => :keep_alive,
               '0' => :choke,
               '1' => :unchoke,
               '2' => :interested,
               '3' => :not_interested,
               '4' => :have,
               '5' => :bitfield,
               '6' => :request,
               '7' => :piece,
               '8' => :cancel,
               '9' => :port }.freeze

  attr_reader :peer, :length, :type, :payload

  def initialize(peer, length, id, payload)
    @peer = peer
    @length = length
    @type = MESSAGES[id.to_s]
    @payload = payload
  end

  # parse peer info and push data to message_queue
  # @param [Peer] peer
  # @param [Queue] message_queue
  def self.parse_stream(peer, message_queue)
    loop do
      begin
        length = peer.connection.read(4).unpack('N')[0]
        id = length.zero? ? '-1' : peer.connection.readbyte.to_s
        payload = has_payload?(id) ? peer.connection.read(length - 1) : nil

        # push message to the queue
        message_queue << Message.new(peer, length, id, payload)
      rescue => exception
        PrettyLog.error("#{__FILE__}:#{__LINE__} #{exception}")
        break
      end
    end
  end

  # returns true if message id has payload
  # @param [Fixnum] id
  def self.has_payload?(id)
    # messages with id == 4...9 have payload
    # see https://wiki.theory.org/BitTorrentSpecification#Messages for reference
    /[456789]/.match(id)
  end

  # send keep-alive message
  # @param [Peer] peer
  def self.send_keep_alive(peer)
    loop do
      begin
        peer.connection.write("\0\0\0\0")
      rescue => exception
        PrettyLog.error("keep alive :: exception :: #{exception}")
      end
      sleep(120) # Keepalives are generally sent once every two minutes
    end
  end

  # send choke message
  # @param [Peer] peer
  def self.send_choke(peer)
    length = "\0\0\0\1"
    id = "\0"
    peer.connection.write(length + id)
  end

  # send unchoke message
  # @param [Peer] peer
  def self.send_unchoke(peer)
    length = "\0\0\0\1"
    id = "\1"
    peer.connection.write(length + id)
  end

  # send interested message
  # @param [Peer] peer
  def self.send_interested(peer)
    length = "\0\0\0\1"
    id = "\2"
    peer.connection.write(length + id)
  end

  # send not interested message
  # @param [Peer] peer
  def self.send_not_interested(peer)
    length = "\0\0\0\1"
    id = "\3"
    peer.connection.write(length + id)
  end

  # send have message
  # @param [Array] peers
  # @param index
  def self.send_have(peers, index)
    length = "\0\0\0\5" # The have message is fixed length
    id = "\4"
    piece_index = [index].pack('N')
    peers.each do |peer|
      peer.connection.write(length + id + piece_index)
    end
  end

  # request: <len=0013><id=6><index><begin><length>
  # @param [Hash] request
  def self.send_request(request)
    connection = request[:connection]
    msg_length = "\0\0\0\x0d" # 13
    id = "\6"
    piece_index = [request[:index]].pack('N')
    offset = [request[:offset]].pack('N')
    request_length = [request[:size]].pack('N')
    req = msg_length + id + piece_index + offset + request_length

    connection.write(req)
  end
end
