require "./handler"

module Crumble::Server
  module ViewHandler
    extend Handler

    getter request_ctx : Crumble::Server::RequestContext | Crumble::Server::TestRequestContext

    getter ctx : Crumble::Server::HandlerContext? do
      Crumble::Server::HandlerContext.new(request_ctx, self)
    end

    abstract def window_title : String?
  end
end
