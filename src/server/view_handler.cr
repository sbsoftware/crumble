require "./handler"

module Crumble::Server
  module ViewHandler
    extend Handler

    getter request_ctx : Crumble::Server::RequestContext | Crumble::Server::TestRequestContext

    getter ctx : Crumble::Server::HandlerContext? do
      Crumble::Server::HandlerContext.new(request_ctx, self)
    end

    abstract def window_title : String?

    def og_title : String?
      nil
    end

    def og_description : String?
      nil
    end

    def meta_description : String?
      nil
    end

    def og_image : String?
      nil
    end

    def og_image_alt : String?
      nil
    end

    def og_url : String?
      nil
    end

    def og_type : String?
      nil
    end

    def og_site_name : String?
      nil
    end

    def twitter_card : String?
      nil
    end

    def twitter_title : String?
      nil
    end

    def twitter_description : String?
      nil
    end

    def twitter_image : String?
      nil
    end

    def twitter_image_alt : String?
      nil
    end
  end
end
