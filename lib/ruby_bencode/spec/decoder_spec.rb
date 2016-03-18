require 'spec_helper'

describe Bencode::Decoder do
  it 'returns nil on decode nil' do
    expect(Bencode::Decoder.decode(nil)).to eq nil
  end

  it 'decodes integer' do
    expect(Bencode::Decoder.decode('i10e')).to eq 10
  end

  it 'decodes string' do
    expect(Bencode::Decoder.decode('6:foobar')).to eq 'foobar'
  end

  it 'decodes hash' do
    bencoded_string = 'd3:bar4:spam3:fooi42ee'
    hash = { 'bar' => 'spam', 'foo' => 42 }
    expect(Bencode::Decoder.decode(bencoded_string)).to eq hash
  end
end
