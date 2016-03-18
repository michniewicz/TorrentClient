require 'stringio'

##
# Describes Bencode class and its methods
#
# Examples:
#
# Bencode::Encoder.encode({ encoding: 'UTF-8', path: "1.png" })
# => 'd8:encoding5:UTF-84:path5:1.pnge'
# Bencode::Decoder.decode('d3:bar4:spam3:fooi42ee')
# => { 'bar' => 'spam', 'foo' => 42 }
#

class Bencode
  ##
  # Describes Decoder class and its methods
  #
  class Decoder
    # Decodes given string
    # Returns decoded string
    def self.decode(string)
      parse string
    end

    # Decodes torrent (or other bencoded file) at given path
    # Returns decoded data as String
    def self.decode_file(path)
      decode(File.open(path, 'rb').read)
    end

    def self.parse(obj)
      io = init_io(obj)

      case peek(io)
      when 'i'
        parse_integer io
      when 'l'
        parse_list io
      when 'd'
        parse_dict io
      when '0'..'9'
        parse_string io
      end
    end

    def self.parse_list(io)
      io.getc if peek(io) == 'l'
      parse_io_list io
    end

    def self.parse_dict(io)
      io.getc if peek(io) == 'd'
      key_value_array = parse_list(io)
      Hash[*key_value_array]
    end

    def self.parse_io_list(io)
      array = []
      array.push(parse(io)) until peek(io) == 'e'
      io.getc
      array
    end

    def self.parse_integer(io)
      io.getc
      num = io.gets('e')
      raise DecodeError unless num
      num.chop.to_i
    end

    def self.parse_string(io)
      num = io.gets(':')
      raise DecodeError, 'invalid string length' unless num

      begin
        length = num.chop.to_i
        str = io.read(length)
      rescue
        raise DecodeError, 'invalid string length'
      end

      str
    end

    def self.peek(io)
      c = io.getc
      io.ungetc c
      c
    end

    def self.init_io(obj)
      if obj.is_a?(IO) || obj.is_a?(StringIO)
        io = obj
      elsif obj.respond_to? :to_s
        io = StringIO.new obj.to_s
      else
        io = StringIO.new obj
      end

      io
    end

    class DecodeError < StandardError; end #:nodoc:
  end

  ##
  # Describes Encoder class and its methods
  #
  class Encoder
    # Encodes given object
    # Returns encoded data as String
    def self.encode(obj)
      case obj
      when Integer
        encode_integer obj
      when Symbol # in case someone wants to encode hash with symbols
        encode obj.to_s
      when String
        encode_string obj
      when Array
        encode_array obj
      when Hash
        encode_hash obj
      else
        raise EncodeError
      end
    end

    def self.encode_string(string)
      "#{string.length}:#{string}"
    end

    def self.encode_integer(int)
      "i#{int}e"
    end

    def self.encode_array(array)
      "l#{array.map { |el| encode(el) }.join}e"
    end

    def self.encode_hash(hash)
      "d#{hash.map { |key, val| "#{encode(key)}#{encode(val)}" }.join}e"
    end

    class EncodeError < StandardError #:nodoc:
      def to_s
        'Cannot encode given object type'
      end
    end
  end
end
