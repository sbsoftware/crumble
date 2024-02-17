require "../spec_helper"

module Crumble::Resource::RedirectSpec
  class MyResource < ::Resource
    layout nil

    def create
      redirect self.class.uri_path(1)
    end
  end

  context "with a `POST /my` request" do
    orig_ctx = Crumble::Server::TestRequestContext.new(resource: "/crumble/resource/redirect_spec/my", method: "POST")
    session_store = Crumble::Server::MemorySessionStore(Crumble::Server::Session).new
    ctx = Crumble::Server::RequestContext.new(session_store, orig_ctx)
    MyResource.handle(ctx)

    ctx.response.status_code.should eq(303)
    ctx.response.headers["Location"].should eq("/crumble/resource/redirect_spec/my/1")
  end
end
