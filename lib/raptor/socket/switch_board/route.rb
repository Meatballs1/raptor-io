require 'ipaddr'

#
# A logical switch board route.
#
class Raptor::Socket::SwitchBoard::Route
  include Comparable

  # @param subnet [String,IPAddr]  The network associated with this
  #   route. If specified as a String, must be parseable by IPAddr.new
  # @param netmask [String,IPAddr] `subnet`'s netmask. If specified as
  #   a String, must be parseable by IPAddr.new
  # @param comm [Comm] The endpoint where sockets for this route
  #   should be created.
  def initialize(subnet, netmask, comm)
    self.netmask     = netmask.kind_of?(IPAddr) ? netmask : IPAddr.new(netmask)
    self.subnet      = (subnet.kind_of?(IPAddr) ? subnet  : IPAddr.new(subnet)).mask netmask.to_s

    self.comm        = comm
  end

  #
  # For direct equality, make sure all the attributes are the same
  #
  def ==(other)
    return false unless other.kind_of? Raptor::Socket::SwitchBoard::Route
    netmask == other.netmask && subnet == other.subnet && comm == other.comm
  end

  #
  # For comparison, sort according to netmask.
  #
  # This allows {Route routes} to be ordered by specificity
  #
  def <=>(other)
    netmask <=> other.netmask
  end

  attr_reader :subnet, :netmask, :comm
protected
  attr_writer :subnet, :netmask, :comm
end
