require 'fileutils'

class FileLoader
  include FileUtils

  DOWNLOAD_DIRECTORY_NAME = 'downloads'

  def initialize(meta_info)
    @meta_info = meta_info
    @byte_array = ByteArray.new(@meta_info)
    @download_path = "#{DOWNLOAD_DIRECTORY_NAME}/"
    @download_progress = 0

    @files = Array.new
    if @meta_info.single_file?
      temp_n = "#{DOWNLOAD_DIRECTORY_NAME}/#{@meta_info.files[0][:name]}"
      file = init_file(DOWNLOAD_DIRECTORY_NAME, temp_n)
      @files << file
    else
      init_files(DOWNLOAD_DIRECTORY_NAME)
    end

  end

  # process given block and write bytes from block to file
  # @param [Block] block
  def process(block)
    write_files(block)
    record(block)

    set_download_progress
    finish if @byte_array.complete?
  end

  private

  # track saved piece of data from files
  def record(block)
    begin
      @byte_array.record_bytes(block.start_byte, block.end_byte)
    rescue => exception
      PrettyLog.error("#{__FILE__}:#{__LINE__} #{exception}")
    end
  end

  # update progress of downloading
  def set_download_progress
    files_size = @files.inject(0){|sum,file| sum + file.size }
    @download_progress = ((100 / @meta_info.total_size.to_f) * files_size).to_i
    PrettyLog.info("... #{@download_progress}% so far ...")
  end

  # finish download operations and close the service
  def finish
    @files.each do |file|
      file.close
    end

    # let the tracker know we have completed downloading
    req = NetworkHelper::get_request(@meta_info.announce, TrackerInfo.tracker_params(@meta_info, @meta_info.total_size, :completed))

    puts 'finish'
    ThreadHelper::exit_threads # TODO implement seeding
  end

  ####### file operations #######

  # writes data to file
  # @param [File] file
  # @param [String] data
  # @param [Integer] file_offset
  def write_to_file(file, data, file_offset)
    file.seek(file_offset)
    file.binmode # make sure file is in binmode for avoid ASCII-8BIT to UTF-8 error conversion
    file.write(data)
  end

  # writes data to files
  # @param [Block] block
  def write_files(block)
    start_byte = block.start_byte
    @meta_info.files.each_with_index do |f, index|

      file = @files[index]
      if start_byte >= f[:start_byte] && start_byte <= f[:end_byte]

        if f[:start_byte] + block.data.bytesize > f[:end_byte]
          PrettyLog.error("Ouch... bytesize to write > end of file #{file.path}")
        end
        current_file_offset = start_byte - f[:start_byte]
        current_file_endbyte = f[:length]-1
        PrettyLog.error("Why did yhis happen? real_offset < 0") if current_file_offset < 0
        current_file_offset = 0 if current_file_offset < 0
        if current_file_offset + block.data.bytesize > current_file_endbyte

          current_file_bytes_count = current_file_endbyte - current_file_offset + 1
          part = block.data.byteslice(0, current_file_bytes_count)
          write_to_file(file, part, current_file_offset)

          next_file_bytes = block.data.byteslice(current_file_bytes_count, block.data.length)
          if @files[index+1]
            next_file = @files[index+1]
            write_to_file(next_file, next_file_bytes, 0)
          end
          break
        end

        write_to_file(file, block.data, current_file_offset)
        break
      end
    end
  end

  # read length bytes from the given start offset
  # @param [Fixnum] start
  # @param [Fixnum] length
  def read(file, start, length)
    file.seek(start)
    file.read(length)
  end

  # removes file from the directory
  # @param [String] filename
  def remove_file(filename)
    File.delete(filename)
  end

  # creates directory if not exists
  # opens the file at selected file_name with read-write modes
  # @param folder_name [String]
  # @param file_name [String]
  def init_file(folder_name, file_name)
    Dir.mkdir("#{folder_name}") unless File.directory?("#{folder_name}")
    File.open(file_name, 'wb+')
    File.open(file_name, 'r+')
  end

  # creates directories if not exist
  # opens the files at selected file_name's with read-write modes
  # @param folder_name [String]
  # @return [Array] @files
  def init_files(folder_name)
    files_subdirectory = "#{folder_name}/#{@meta_info.folder}"
    Dir.mkdir("#{folder_name}") unless File.directory?("#{folder_name}")
    Dir.mkdir(files_subdirectory) unless File.directory?(files_subdirectory)
    @meta_info.files.each do |file|
      path_array = file[:name].split('/')
      last_index = path_array.count-1
      if path_array.count > 1 # file in the nested directory(ies)
        nested_directory = path_array[0...last_index].join('/') # get nested folders from path
        FileUtils.mkdir_p "#{files_subdirectory}/#{nested_directory}"

        add_file( "#{files_subdirectory}/#{nested_directory}/#{path_array[last_index]}" )
      else
        add_file( "#{files_subdirectory}/#{file[:name]}" )
      end
    end
  end

  # initialize and add file to @files array at provided path
  # @param [String] path
  def add_file(path)
    File.open("#{path}", 'wb+')
    f = File.open("#{path}", 'r+')

    @files << f
  end
end
