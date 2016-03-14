##
# Represents MetaInfo class
# contains metainfo of given torrent file and helper methods
#
class MetaInfo
  attr_reader :info_hash, :announce, :number_of_pieces,
              :pieces, :files, :total_size, :piece_length

  def initialize(meta_info)
    @info = meta_info['info']
    @info_hash = Digest::SHA1.new.digest(@info.bencode)

    @piece_length = @info['piece length']
    @number_of_pieces = @info['pieces'].length / 20

    @announce = meta_info['announce']

    set_total_size
    set_files
    set_pieces
  end

  # sets size of all files recorded in torrent
  def set_total_size
    if single_file?
      @total_size = @info['length']
    else
      @total_size = count_size(@info['files'])
    end
  end

  # returns size of selected files described in metainfo
  # @param [Array] files
  # @return files size
  def get_selected_size(files = nil)
    return @total_size unless files
    count_size(files)
  end

  # get folder name of multiple-files torrent
  # @return [String] folder
  def folder
    !single_file? ? @info['name'] : ''
  end

  # initializes files array by parsing info hash from metainfo
  def set_files
    @files = []
    if single_file?
      add_file(@info['name'], @info['length'], 0, @info['length'] - 1)
    else
      add_files
    end
  end

  def add_files
    @info['files'].inject(0) do |start_byte, file|
      path = file['path']
      # check whether it is nested path
      name = path.count > 1 ? path.join('/') : path[0]
      end_byte = start_byte + file_length(file) - 1

      add_file(name, file_length(file), start_byte, end_byte)
      start_byte + file_length(file)
    end
  end

  def add_file(name, length, start_byte, end_byte)
    @files << { name: name, length: length, start_byte: start_byte, end_byte: end_byte }
  end

  # initializes pieces array with pieces parsed from metainfo
  def set_pieces
    @pieces = []
    (0...@number_of_pieces).each do |index|
      start_byte = index * @piece_length
      end_byte = get_end_byte(start_byte, index)
      hash = get_correct_hash(index)

      @pieces << { hash: hash,
                   start_byte: start_byte,
                   end_byte: end_byte,
                   length: (end_byte - start_byte + 1) }
    end
  end

  # returns end byte of piece by selected index depending on start_byte
  # @param [String] start_byte
  # @param [Fixnum] index
  # @return [Fixnum] end_byte
  def get_end_byte(start_byte, index)
    return @total_size - 1 if last_piece?(index)
    start_byte + @piece_length - 1
  end

  # returns true if piece at selected index is last
  # @param [Fixnum] index
  def last_piece?(index)
    index == @number_of_pieces - 1
  end

  # returns hash of piece at selected index
  # @param [Fixnum] index
  # @return [String] hash
  def get_correct_hash(index)
    # multiply by 20 since there are 20-byte SHA1 hash values
    @info['pieces'][20 * index...20 * (index + 1)]
  end

  # returns true if single file torrent
  def single_file?
    @info['files'].nil?
  end

  # returns file length from metainfo files
  # @param [Hash] file
  def file_length(file)
    file['length']
  end

  def count_size(files)
    size = files.inject(0) do |start_byte, file|
      start_byte + file_length(file)
    end
    size
  end
end
