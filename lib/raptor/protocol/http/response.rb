require 'zlib'
require 'stringio'

module Raptor
module Protocol::HTTP

#
# HTTP Response.
#
# @author Tasos Laskos <tasos_laskos@rapid7.com>
#
class Response < Message

  # @return [Integer] HTTP response status code.
  attr_reader :code

  # @return [String] HTTP response status message.
  attr_reader :message

  # @return [Request] HTTP {Request} which triggered this {Response}.
  attr_accessor :request

  #
  # @note This class' options are in addition to {Message#initialize}.
  #
  # @param  [Hash]  options Request options.
  # @option options [Integer] :code HTTP response status code.
  # @option options [Request] :request HTTP request that triggered this response.
  #
  # @see Message#initialize
  #
  def initialize( options = {} )
    super( options )

    @code ||= 0
  end

  # @return [String]
  #   String representation of the response.
  def to_s
    return @original if @original

    r = "HTTP/#{version} #{code}"
    r <<  " #{message}" if message
    r <<  "\r\n"
    r << "#{headers.to_s}\r\n\r\n"
    r << body
  end

  # @param  [String]  response  HTTP response.
  # @return [Response]
  def self.parse( response )
    options ||= {}

    # Since we've got the original response store it to be returned by {#to_s}.
    options[:original] = response

    headers_string, options[:body] = response.split( "\r\n\r\n", 2 )
    request_line   = headers_string.to_s.lines.first.to_s.chomp

    options[:version], options[:code], options[:message] =
        request_line.scan( /HTTP\/([\d.]+)\s+(\d+)\s*(.*)\s*$/ ).flatten

    options.delete(:message) if options[:message].to_s.empty?

    options[:code] = options[:code].to_i

    if !headers_string.to_s.empty?
      options[:headers] =
          Headers.parse( headers_string.split( /[\r\n]+/ )[1..-1].join( "\r\n" ) )
    else
      options[:headers] = Headers.new
    end

    case options[:headers]['content-encoding'].to_s.downcase
      when 'gzip', 'x-gzip'
        options[:body] = unzip( options[:body] )
      when 'deflate', 'compress', 'x-compress'
        options[:body] = inflate( options[:body] )
    end

    new( options )
  end

  # @param  [String]  str Inflates `str`.
  # @return [String]  Inflated `str`.
  def self.inflate( str )
    z = Zlib::Inflate.new
    s = z.inflate( str )
    z.close
    s
  end

  # @param  [String]  str Unzips `str`.
  # @return [String]  Unziped `str`.
  def self.unzip( str )
    s = ''
    s.force_encoding( 'ASCII-8BIT' ) if s.respond_to?( :encoding )
    gz = Zlib::GzipReader.new( StringIO.new( str, 'rb' ) )
    s << gz.read
    gz.close
    s
  end

  protected

  def original=( response )
    @original = response
  end

end

end
end
