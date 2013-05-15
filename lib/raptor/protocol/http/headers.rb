require 'uri'

module Raptor
module Protocol::HTTP

#
# HTTP Headers, holds shared attributes of {Request} and {Response}.
#
# @author Tasos Laskos <tasos_laskos@rapid7.com>
#
class Headers < Hash

  # @param  [Headers, Hash] headers
  def initialize( headers = {} )
    merge!( headers || {} )
  end

  # @return [String]  HTTP headers formatted for transmission.
  def to_s
    map { |k, v| "#{URI.encode(k)}: #{URI.encode(v)}" }.join( "\r\n" )
  end

  # @param  [String]  headers_string
  # @return [Headers]
  def self.parse( headers_string )
    headers = Headers.new
    return headers if headers_string.to_s.empty?

    headers_string.split( /[\r\n]+/ ).each do |header|
      k, v = header.split( ':', 2 )
      k = CGI.unescape( k.to_s.strip )
      v = CGI.unescape( v.to_s.strip )
      headers[k] = v
    end
    headers
  end

end

end
end
