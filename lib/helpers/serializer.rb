require 'json'
module Serializer
  def self.serialize(file_name, object)
    File.open(file_name, 'a') {|f| f.write(object.to_json) }
  end

  def self.deserialize(file_name)
    JSON.parse(File.read(file_name))
  end
end
