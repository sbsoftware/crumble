require "./test_request"
require "./test_response"

class Crumble::Server::TestRequestContext < HTTP::Server::Context
  def initialize(response_io = nil, **request_args)
    @request = TestRequest.new(**request_args)
    @response = TestResponse.new(response_io || IO::Memory.new)
  end

  def session
    nil
  end
end
