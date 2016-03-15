require 'json'
##
# Represents Serializer module
# helper module for files serialize/deserialize
#
module Serializer
  def self.serialize(file_name, object)
    File.open(file_name, 'w') { |f| f.write(object.to_json) }
  end

  def self.deserialize(file_name)
    JSON.parse(File.read(file_name))
  end
end
