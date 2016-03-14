##
# Represents Bitfield class and its methods
# contains array of bits
#
class Bitfield
  attr_reader :bits

  def initialize(bit_array)
    # ex. ["10000000"] to [1, 0, 0, 0, 0, 0, 0, 0]
    @bits = bit_array.join.split('').map!(&:to_i)
  end

  def have_piece(index)
    @bits[index] = 1
  end
end
