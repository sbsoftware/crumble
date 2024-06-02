require "./session_store"
require "./session_decorator"

class Crumble::Server::RequestContext
  SESSION_COOKIE_NAME = "_crumble_session"

  @@session_store : SessionStore?

  getter original_context : HTTP::Server::Context

  delegate request, response, to: original_context

  def initialize(@original_context)
  end

  def self.session_store
    return @@session_store.not_nil! if @@session_store

    @@session_store = init_session_store
  end

  # Override to change the session store implementation
  def self.init_session_store
    MemorySessionStore.new
  end

  def session_store
    self.class.session_store
  end

  def session
    @session ||= SessionDecorator.new(session_store, load_session)
  end

  # Override this method to change the session cookie lifetime
  # TODO: Think about how to properly test this
  def session_cookie_max_age
    nil
  end

  private def load_session
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
    response.cookies << HTTP::Cookie.new(name: SESSION_COOKIE_NAME, value: new_key.to_s, path: "/", max_age: session_cookie_max_age)
    session_store.set(s)
    s
  end
end
