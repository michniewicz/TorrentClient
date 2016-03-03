class Peer
  
  attr_reader :id, :connection, :bitfield
  attr_accessor :pending_requests

  def initialize(host, port, handshake, correct_info_hash)
    @pending_requests = []
    @connection = TCPSocket.new(IPAddr.ntop(host), port)
    @correct_info_hash = correct_info_hash
    perform_handshake(handshake)
    set_bitfield

    @id = @handshake_hash[:peer_id]
  end

  def perform(message_queue)
    Thread.new { Message.parse_stream(self, message_queue) }
    Thread.new { Message.send_keep_alive(self) }
    Message.send_interested(self)
  end

  private

  def perform_handshake(handshake)
    @connection.write(handshake)
    set_handshake_hash
    verify_handshake
  end

  def set_handshake_hash
    pstrlen = @connection.getbyte
    @handshake_hash = { pstrlen: pstrlen,
                        # string identifier of the protocol
                        pstr: @connection.read(pstrlen),
                        # eight (8) reserved bytes.
                        reserved: @connection.read(8),
                        # 20-byte SHA1 hash of the info key in the metainfo file
                        info_hash: @connection.read(20),
                        # 20-byte string used as a unique ID for the client
                        peer_id: @connection.read(20) }
  end

  def verify_handshake
    close_connection unless @handshake_hash[:info_hash] == @correct_info_hash
  end

  def close_connection
    @connection.shutdown
    @connection.close
  end

  def set_bitfield
    length = @connection.read(4).unpack('N')[0] # get length from the connection and unpack it to Integer
    message_id = @connection.read(1).bytes[0] # read message ID
    if message_id == 5 # bitfield id is 5
      @bitfield = Bitfield.new(@connection.read(length - 1).unpack('B8' * (length - 1)))
    else # not a bitfield
      @bitfield = nil
    end
  end
end

