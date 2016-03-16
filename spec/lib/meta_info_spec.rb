require 'spec_helper'

describe MetaInfo do
  let(:meta_info) { MetaInfo.new(BEncode.load_file('spec/fixtures/test.torrent')) }

  it 'returns folder' do
    expect(meta_info.folder.force_encoding('UTF-8')).to eq 'test_folder'
  end

  it '#single_file?' do
    expect(meta_info.single_file?).to be false
  end

  it 'returns files count' do
    expect(meta_info.files.count).to eq 6
  end

  it 'returns total_size' do
    expect(meta_info.total_size).to eq 7_068_431
  end

  it 'returns piece_length' do
    expect(meta_info.piece_length).to eq 32_768
  end

  it 'returns number_of_pieces' do
    expect(meta_info.number_of_pieces).to eq 216
  end

  it '#last_piece?' do
    expect(meta_info.last_piece?(215)).to be true
  end

  it '#get_correct_hash' do
    piece = meta_info.pieces[0]
    file = File.open('spec/fixtures/test_folder/1.png')
    bytes = read_bytes(file, piece[:start_byte], piece[:length])
    expect(meta_info.get_correct_hash(0)).to eq Digest::SHA1.new.digest(bytes)
  end
end
