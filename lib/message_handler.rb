##
# Represents MessageHandler class and its methods
# processes given messages
#
class MessageHandler
  def initialize(piece_length)
    @piece_length = piece_length
  end

  # incoming messages processor method
  # @param [Message] message
  # @param [Array] output
  def process(message, output)
    puts "Got message #{message.type} from peer: #{message.peer.id}"
    case message.type
    when :piece
      piece_index, byte_offset, block_data = split_piece_payload(message.payload)
      block = Block.new(piece_index, byte_offset, block_data, message.peer, @piece_length)
      remove_from_pending(block)
      output.push(block)
    when :have
      message.peer.bitfield.have_piece(message.payload.unpack('N')[0])
      # A malicious peer might choose to advertise having pieces
      # that it knows the peer will never download.
      # TODO handle this case if possible
    else
      puts "currently not processed or ignored message type - #{message.type}"
    end
  end

  private

  def remove_from_pending(block)
    block.peer.pending_requests.delete_if do |req|
      req && req[:index] == block.piece_index && req[:offset] == block.offset
    end
  end

  def split_piece_payload(payload)
    piece_index = payload.slice!(0..3).unpack('N')[0]
    byte_offset = payload.slice!(0..3).unpack('N')[0]
    block_data = payload
    [piece_index, byte_offset, block_data]
  end
end
