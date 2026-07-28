require "./session_store"
require "./session_decorator"

class Crumble::Server::RequestContext
  SESSION_COOKIE_NAME = "_crumble_session"

  @@session_store : SessionStore?
  @session_id : SessionKey?

  getter session_id : SessionKey do
    ensure_session_key
  end
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

  # Override this method to allow JavaScript access to the session cookie
  def session_cookie_http_only
    true
  end

  # Override this method to change the session cookie SameSite policy
  def session_cookie_same_site
    :lax
  end

  # Override this method to allow session cookies over plain HTTP
  def session_cookie_secure
    {% if flag?(:release) %}
      true
    {% else %}
      false
    {% end %}
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

  private def ensure_session_key : SessionKey
    if session_key = @session_id
      return session_key
    end

    session_key = if cookie = request.cookies[SESSION_COOKIE_NAME]?
                    if uuid = UUID.parse?(cookie.value)
                      SessionKey.new(uuid)
                    else
                      # Bad client cookies should not break requests that never touch sessions.
                      set_new_session_key_cookie
                    end
                  else
                    set_new_session_key_cookie
                  end

    @session_id = session_key
    session_key
  end

  private def session_cookie_samesite
    case same_site = session_cookie_same_site
    when nil
      nil
    when HTTP::Cookie::SameSite
      same_site
    when Symbol
      case same_site
      when :lax
        HTTP::Cookie::SameSite::Lax
      when :strict
        HTTP::Cookie::SameSite::Strict
      when :none
        HTTP::Cookie::SameSite::None
      else
        raise ArgumentError.new("Unsupported session cookie SameSite value: #{same_site.inspect}")
      end
    else
      raise ArgumentError.new("Unsupported session cookie SameSite value: #{same_site.inspect}")
    end
  end

  private def set_new_session_key_cookie : SessionKey
    session_key = SessionKey.generate
    response.cookies << HTTP::Cookie.new(name: SESSION_COOKIE_NAME, value: session_key.to_s, path: "/", max_age: session_cookie_max_age, http_only: session_cookie_http_only, samesite: session_cookie_samesite, secure: session_cookie_secure)
    session_key
  end
end
