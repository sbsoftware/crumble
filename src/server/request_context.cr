require "./session_store"
require "./session_decorator"

class Crumble::Server::RequestContext
  SESSION_COOKIE_NAME = "_crumble_session"

  @@session_store : SessionStore?
  @session_key : SessionKey?

  getter original_context : HTTP::Server::Context

  delegate request, response, to: original_context

  def initialize(@original_context)
    ensure_session_key
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
    key = ensure_session_key
    if session_store.has_key?(key)
      session_store[key]
    else
      session = Session.new(key)
      session_store.set(session)
      session
    end
  end

  private def ensure_session_key
    return @session_key.not_nil! if @session_key

    if request.cookies.has_key?(SESSION_COOKIE_NAME)
      begin
        @session_key = SessionKey.new(UUID.new(request.cookies[SESSION_COOKIE_NAME].value))
      rescue ArgumentError
        # Bad client cookies should not break requests that never touch sessions.
        set_new_session_key_cookie
      end
    else
      set_new_session_key_cookie
    end

    @session_key.not_nil!
  end

  private def set_new_session_key_cookie
    @session_key = SessionKey.generate
    response.cookies << HTTP::Cookie.new(name: SESSION_COOKIE_NAME, value: @session_key.not_nil!.to_s, path: "/", max_age: session_cookie_max_age)
  end
end
