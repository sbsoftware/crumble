require "./test_request"
require "./test_response"

class Crumble::Server::TestRequestContext < Crumble::Server::RequestContext
  def initialize(response_io = nil, session_store = nil, **request_args)
    request = TestRequest.new(**request_args)
    response = TestResponse.new(response_io)
    @original_context = HTTP::Server::Context.new(request, response)
    @session_store = session_store || MemorySessionStore.new
  end

  def session_store
    @session_store
  end
end
