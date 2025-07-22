require "http"

class Crumble::Server::TestRequest < HTTP::Request
  getter id : String
  getter resource : String
  getter method : String
  getter headers : HTTP::Headers

  def initialize(id = nil, resource = "/", method = "GET", headers = nil, remote_address : String = "127.0.0.1", body : String? = nil)
    @id = id if id
    @remote_address = Socket::IPAddress.new(remote_address, 80)
    body_io = IO::Memory.new.tap { |io| io << body; io.rewind } if body
    super(method: method, resource: resource, headers: headers, body: body_io, internal: nil)
  end
end
