require 'cgi'
require 'uri'

#
# HTTP protocol implementation.
#
# @author Tasos Laskos <tasos_laskos@rapid7.com>
#
module Raptor::Protocol::HTTP
end

require 'raptor/protocol/http/headers'
require 'raptor/protocol/http/pdu'
require 'raptor/protocol/http/request'
require 'raptor/protocol/http/response'
require 'raptor/protocol/http/client'
