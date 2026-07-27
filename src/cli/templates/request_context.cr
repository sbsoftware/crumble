module Crumble
  module Server
    class RequestContext
      # Configure your server here by uncommenting/changing the needed methods

      # Default is a memory store that will be erased after each server restart.
      #
      # The folder needs to exist already.
      # def self.init_session_store
      #   FileSessionStore.new("tmp/sessions")
      # end

      # Leaving this at `nil` will lead to the cookies being just session cookies.
      # def session_cookie_max_age
      #   365.days
      # end

      # def session_cookie_http_only
      #   true
      # end

      # def session_cookie_same_site
      #   :lax
      # end

      # Release builds default this to true. Override in development if you need
      # cookies to be set over plain HTTP.
      # def session_cookie_secure
      #   false
      # end

      # Add any methods you want to access on the `ctx` object in resources or views
    end
  end
end
