class Crumble::Server::TestRequest < HTTP::Request
  getter id : String
  getter resource : String
  getter method : String
  getter headers : HTTP::Headers

  def initialize(id = nil, resource = "/", method = "GET", headers = nil, remote_address : String = "127.0.0.1")
    @id = id if id
    @remote_address = Socket::IPAddress.new(remote_address, 80)
    super(method: method, resource: resource, headers: headers, internal: nil)
  end
end
