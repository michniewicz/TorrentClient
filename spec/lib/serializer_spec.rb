require 'spec_helper'

describe Serializer do
  let(:file_name) { 'test.dat' }
  let(:hash_obj) { { foo: 'foo', bar: 'bar', arr: %w(1 2 true) } }

  it '#serialize' do
    res = Serializer.serialize(file_name, hash_obj)
    expect(res).to eq hash_obj.to_json.bytesize
  end

  it '#deserialize' do
    res = Serializer.deserialize(file_name)

    expect(res['foo']).to eq hash_obj[:foo]
    expect(res['bar']).to eq hash_obj[:bar]
    expect(res['arr']).to eq hash_obj[:arr]

    File.delete(file_name)
  end
end
