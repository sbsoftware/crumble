require "./handler"
require "./request_context"

module Crumble::Server
  struct HandlerContext
    getter request_context : Crumble::Server::RequestContext | Crumble::Server::TestRequestContext
    getter handler : Crumble::Server::Handler

    forward_missing_to request_context

    def initialize(@request_context, @handler); end
  end
end
