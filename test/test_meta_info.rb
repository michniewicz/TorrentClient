require 'test/unit'
require 'digest/sha1'
require_relative '../lib/meta_info'
require_relative '../lib/ruby-bencode/lib/bencode'
require_relative 'test_helper'

class TestMetaInfo < Test::Unit::TestCase
  def setup
    file = File.open('test/fixtures/test.torrent')
    @meta_info = MetaInfo.new(BEncode::Parser.new(file).parse!)
  end

  def test_folder
    assert_equal(@meta_info.folder.force_encoding('UTF-8'), 'test_folder')
  end

  def test_single_file?
    assert_false(@meta_info.single_file?)
  end

  def test_files_count
    assert_equal(@meta_info.files.count, 6)
  end

  def test_total_size
    assert_equal(@meta_info.total_size, 7_068_431)
  end

  def test_piece_length
    assert_equal(@meta_info.piece_length, 32_768)
  end

  def test_number_of_pieces
    assert_equal(@meta_info.number_of_pieces, 216)
  end

  def test_last_piece?
    assert_true(@meta_info.last_piece?(215))
  end

  def test_correct_hash
    piece = @meta_info.pieces[0]
    file = File.open('test/fixtures/test_folder/1.png')
    bytes = TestHelper.read(file, piece[:start_byte], piece[:length])
    assert_equal(@meta_info.get_correct_hash(0), Digest::SHA1.new.digest(bytes))
  end
end
