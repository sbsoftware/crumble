require "../src/server/request_context"
require "./test_request"
require "./test_response"

class Crumble::Server::TestRequestContext < Crumble::Server::AbstractRequestContext
  getter request : TestRequest
  getter response : TestResponse

  def initialize(path, method = "GET")
    @request = TestRequest.new(path, method)
    @response = TestResponse.new
  end

  def session
    nil
  end
end
