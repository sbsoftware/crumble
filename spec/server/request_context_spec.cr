require "../spec_helper"

describe Crumble::Server::RequestContext do
  describe "#session" do
    context "when the request has a cookie with a session key" do
      context "when a session with the key exists" do
        it "returns it" do
          session_store = Crumble::Server::MemorySessionStore.new
          existing_session_key = Crumble::Server::SessionKey.generate

          original_request = HTTP::Request.new("POST", "/dummy", nil, nil)
          original_response = HTTP::Server::Response.new(IO::Memory.new)
          original_context = HTTP::Server::Context.new(original_request, original_response)
          request_context = Crumble::Server::RequestContext.new(session_store, original_context)
          original_request.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME] = existing_session_key.to_s
          existing_session = Crumble::Server::Session.new(existing_session_key)
          session_store.set(existing_session)

          request_context.session.should eq(existing_session)
        end
      end

      context "when no session with the key exists in the store" do
        it "returns a new session with a new key" do
          session_store = Crumble::Server::MemorySessionStore.new
          existing_session_key = Crumble::Server::SessionKey.generate

          original_request = HTTP::Request.new("POST", "/dummy", nil, nil)
          original_response = HTTP::Server::Response.new(IO::Memory.new)
          original_context = HTTP::Server::Context.new(original_request, original_response)
          request_context = Crumble::Server::RequestContext.new(session_store, original_context)
          original_request.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME] = existing_session_key.to_s

          request_context.session.id.should_not eq(existing_session_key)
        end
      end
    end
  end
end
