class Block
  attr_reader :piece_index, :offset, :data, :peer, :start_byte, :end_byte

  def initialize(piece_index, offset, data, peer, piece_length)
    @piece_index = piece_index
    @offset = offset
    @data = data
    @peer = peer
    @start_byte = @piece_index * piece_length + @offset
    @end_byte = @start_byte + @data.length - 1
  end

end

  
