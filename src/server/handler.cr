module Crumble::Server
  module Handler
    private module ClassMethods
      abstract def handle(ctx : Crumble::Server::RequestContext) : Bool
    end

    macro included
      extend ClassMethods
    end

    abstract def window_title : String?
  end
end
