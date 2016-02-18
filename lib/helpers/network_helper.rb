require 'uri'
require 'net/http'
require 'socket'
require 'digest/sha1'
require 'ipaddr'
require 'timeout'

module NetworkHelper

  # helper method for GET request performing
  # @param [String] uri
  # @param [Hash] params
  # @return response of get request
  def self.get_request(uri, params)
    begin
      send_get_request(uri, params)
    rescue => exception
      PrettyLog.error("#{__FILE__}:#{__LINE__} #{exception}")

      # retry
      puts 'retrying...'
      get_request(uri, params)
    end
  end

  private

  def self.send_get_request(uri, params)
    request = URI(uri)
    request.query = URI.encode_www_form(params)
    Net::HTTP.get_response(request).body
  end

end
