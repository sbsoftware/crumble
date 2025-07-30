require "./handler"

module Crumble::Server
  module ViewHandler
    extend Handler

    getter request_ctx : Crumble::Server::RequestContext

    def ctx
      @ctx ||= Crumble::Server::HandlerContext.new(request_ctx, self)
    end

    abstract def window_title : String?
  end
end
