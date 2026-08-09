require "../spec_helper"

private class CustomSessionCookieRequestContext < Crumble::Server::TestRequestContext
  def session_cookie_max_age
    2.hours
  end

  def session_cookie_http_only
    false
  end

  def session_cookie_same_site
    :strict
  end

  def session_cookie_secure
    true
  end
end

private class BrowserScopedNewSessionCookieRequestContext < CustomSessionCookieRequestContext
  def new_session_cookie_max_age
    nil
  end
end

private class BrowserScopedReplacementCookieRequestContext < Crumble::Server::RequestContext
  def session_cookie_max_age
    2.hours
  end

  def new_session_cookie_max_age
    nil
  end
end

describe Crumble::Server::RequestContext do
  describe "#initialize" do
    it "sets a session cookie without storing a session when the request has no session cookie" do
      store = Crumble::Server::MemorySessionStore.new
      request_context = Crumble::Server::TestRequestContext.new(session_store: store)

      cookie = request_context.response.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME]
      session_id = Crumble::Server::SessionKey.new(UUID.new(cookie.value))
      request_context.session_id.should eq(session_id)
      store.has_key?(session_id).should be_false
    end

    it "replaces an invalid session cookie without storing a session" do
      original_request = HTTP::Request.new("GET", "/dummy", nil, nil)
      original_request.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME] = "not-a-uuid"
      original_response = HTTP::Server::Response.new(IO::Memory.new)
      original_context = HTTP::Server::Context.new(original_request, original_response)
      Crumble::Server::RequestContext.new(original_context)

      cookie = original_response.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME]
      cookie.value.should_not eq("not-a-uuid")
    end

    it "sets default security flags on new session cookies" do
      request_context = Crumble::Server::TestRequestContext.new
      cookie = request_context.response.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME]

      cookie.http_only.should be_true
      cookie.samesite.should eq(HTTP::Cookie::SameSite::Lax)
      {% if flag?(:release) %}
        cookie.secure.should be_true
      {% else %}
        cookie.secure.should be_false
      {% end %}
    end

    it "allows session cookie security flags to be overridden" do
      request_context = CustomSessionCookieRequestContext.new
      cookie = request_context.response.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME]

      cookie.http_only.should be_false
      cookie.samesite.should eq(HTTP::Cookie::SameSite::Strict)
      cookie.secure.should be_true
    end

    it "uses the configured session lifetime for new cookies by default" do
      request_context = CustomSessionCookieRequestContext.new

      request_context.response.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME].max_age.should eq(2.hours)
    end

    it "allows only new and replacement cookie lifetimes to be overridden" do
      request_context = BrowserScopedNewSessionCookieRequestContext.new

      request_context.response.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME].max_age.should be_nil

      original_request = HTTP::Request.new("GET", "/dummy", nil, nil)
      original_request.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME] = "not-a-uuid"
      original_response = HTTP::Server::Response.new(IO::Memory.new)
      context = HTTP::Server::Context.new(original_request, original_response)
      BrowserScopedReplacementCookieRequestContext.new(context)

      original_response.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME].max_age.should be_nil
    end
  end

  describe "#stored_session?" do
    it "returns false without storing or caching a newly generated session" do
      store = Crumble::Server::MemorySessionStore.new
      request_context = Crumble::Server::TestRequestContext.new(session_store: store)

      request_context.stored_session?.should be_false
      store.has_key?(request_context.session_id).should be_false
    end

    it "returns true when the current session ID exists in the store" do
      store = Crumble::Server::MemorySessionStore.new
      request_context = Crumble::Server::TestRequestContext.new(session_store: store)
      store.set(Crumble::Server::Session.new(request_context.session_id))

      request_context.stored_session?.should be_true
    end
  end

  describe "#refresh_session_cookie" do
    it "reissues the same ID with the configured lifetime and attributes" do
      request_context = BrowserScopedNewSessionCookieRequestContext.new
      session_id = request_context.session_id

      request_context.refresh_session_cookie
      cookie = request_context.response.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME]

      cookie.value.should eq(session_id.to_s)
      cookie.path.should eq("/")
      cookie.max_age.should eq(2.hours)
      cookie.http_only.should be_false
      cookie.samesite.should eq(HTTP::Cookie::SameSite::Strict)
      cookie.secure.should be_true
    end

    it "accepts an explicit lifetime" do
      request_context = BrowserScopedNewSessionCookieRequestContext.new

      request_context.refresh_session_cookie(30.minutes)

      request_context.response.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME].max_age.should eq(30.minutes)
    end
  end

  describe "#session" do
    context "when the request has a cookie with a session key" do
      context "when a session with the key exists" do
        it "returns a decorator containing it" do
          existing_session_key = Crumble::Server::SessionKey.generate

          original_request = HTTP::Request.new("POST", "/dummy", nil, nil)
          original_request.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME] = existing_session_key.to_s
          original_response = HTTP::Server::Response.new(IO::Memory.new)
          original_context = HTTP::Server::Context.new(original_request, original_response)
          request_context = Crumble::Server::RequestContext.new(original_context)
          existing_session = Crumble::Server::Session.new(existing_session_key)
          Crumble::Server::RequestContext.session_store.set(existing_session)

          request_context.session.should be_a(Crumble::Server::SessionDecorator)
          request_context.session.session.should eq(existing_session)
          original_response.cookies.has_key?(Crumble::Server::RequestContext::SESSION_COOKIE_NAME).should be_false
        end
      end

      context "when no session with the key exists in the store" do
        it "returns a decorator with a new session using the request key" do
          existing_session_key = Crumble::Server::SessionKey.generate

          original_request = HTTP::Request.new("POST", "/dummy", nil, nil)
          original_request.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME] = existing_session_key.to_s
          original_response = HTTP::Server::Response.new(IO::Memory.new)
          original_context = HTTP::Server::Context.new(original_request, original_response)
          request_context = Crumble::Server::RequestContext.new(original_context)

          request_context.session.id.should eq(existing_session_key)
          Crumble::Server::RequestContext.session_store.has_key?(existing_session_key).should be_true
          original_response.cookies.has_key?(Crumble::Server::RequestContext::SESSION_COOKIE_NAME).should be_false
        end
      end
    end

    context "when the request has no session cookie" do
      it "stores the generated session on first access" do
        store = Crumble::Server::MemorySessionStore.new
        request_context = Crumble::Server::TestRequestContext.new(session_store: store)
        cookie = request_context.response.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME]
        key = Crumble::Server::SessionKey.new(UUID.new(cookie.value))

        store.has_key?(key).should be_false
        request_context.session.id.should eq(key)
        store.has_key?(key).should be_true
      end
    end
  end
end
