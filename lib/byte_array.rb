##
# Represents ByteArray class and its methods
# class is being used to keep track on recorded bytes
#
class ByteArray
  def initialize(meta_info)
    @length = meta_info.total_size
    @bytes = Array.new([[0, @length - 1, false]])
  end

  # keep track on bytes that were already written to file(s)
  # @param [Fixnum] start_byte
  # @param [Fixnum] end_byte
  def record_bytes(start_byte, end_byte)
    check_range(start_byte, end_byte)

    start_item, end_item = boundary_items(start_byte, end_byte)

    start_index = @bytes.index(start_item)
    end_index = @bytes.index(end_item)

    result = Array.new(3)

    if start_item[2] && end_item[2]
      result[0] = [start_item[0], end_item[1], true]
    elsif start_item[2]
      result[0] = [start_item[0], end_byte, start_item[2]]
      result[1] = [end_byte + 1, end_item[1], end_item[2]]
    elsif end_item[2]
      result[0] = [start_item[0], start_byte - 1, start_item[2]]
      result[1] = [start_byte, end_item[1], true]
    else
      result[0] = [start_item[0], start_byte - 1, start_item[2]]
      result[1] = [start_byte, end_byte, true]
      result[2] = [end_byte + 1, end_item[1], end_item[2]]
    end

    result.map! do |item|
      if !item.nil? && item[0] > item[1]
        item = nil
      end
      item
    end

    result.compact!

    # save result at selected range
    @bytes[start_index..end_index] = result

    # consolidate bytes
    (0...@bytes.length - 1).each do |i|
      if @bytes[i][2] == @bytes[i + 1][2]
        @bytes[i + 1][0] = @bytes[i][0]
        @bytes[i] = nil
      end
    end
    @bytes.compact!
    @bytes
  end

  # returns true if all the bytes for files were loaded and written
  def complete?
    @bytes == [[0, @length - 1, true]]
  end

  private

  # returns array of boundary bytes in stored array of bytes
  # @param [Fixnum] start_byte
  # @param [Fixnum] end_byte
  # @return [Array] array
  def boundary_items(start_byte, end_byte)
    start_item = nil
    end_item = nil
    @bytes.each_with_index do |element, index|
      start_item = @bytes[index] if start_byte.between?(element[0], element[1])
      end_item = @bytes[index] if end_byte.between?(element[0], element[1])
    end
    [start_item, end_item]
  end

  # checks range of given start and end bytes
  # @param [Fixnum] start_byte
  # @param [Fixnum] end_byte
  def check_range(start_byte, end_byte)
    if start_byte < 0 ||
       end_byte < 0 ||
       start_byte > end_byte ||
       start_byte > @length - 1 ||
       end_byte > @length - 1
      raise 'ByteArray :: out of range'
    end
  end
end
