require "./session_store"

class Crumble::Server::RequestContext
  SESSION_COOKIE_NAME = "_crumble_session"

  getter session_store : SessionStore
  getter original_context : HTTP::Server::Context

  delegate request, response, to: original_context

  def initialize(@session_store, @original_context)
  end

  def session
    if request.cookies.has_key?(SESSION_COOKIE_NAME)
      key = SessionKey.new(UUID.new(request.cookies[SESSION_COOKIE_NAME].value))
      if session_store.has_key?(key)
        session_store[key]
      else
        # session does not exist anymore, drop the key and generate a new one
        new_session
      end
    else
      new_session
    end
  end

  private def new_session
    new_key = SessionKey.generate
    s = Session.new(new_key)
    response.cookies << HTTP::Cookie.new(name: SESSION_COOKIE_NAME, value: new_key.to_s, path: "/")
    session_store.set(s)
    s
  end
end
