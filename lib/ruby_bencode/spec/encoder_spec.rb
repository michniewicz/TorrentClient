require 'spec_helper'

describe Bencode::Encoder do
  it 'encodes integer' do
    expect(Bencode::Encoder.encode(10)).to eq 'i10e'
  end

  it 'encodes string' do
    string = 'foobar'
    bencoded_string = '6:foobar'
    expect(Bencode::Encoder.encode(string)).to eq bencoded_string
  end

  it 'encodes array' do
    expect(Bencode::Encoder.encode(%w(foo baar))).to eq 'l3:foo4:baare'
  end

  it 'encodes hash' do
    hash = { encoding: 'UTF-8', path: '1.png' }
    bencoded_hash = 'd8:encoding5:UTF-84:path5:1.pnge'
    expect(Bencode::Encoder.encode(hash)).to eq bencoded_hash
  end
end
