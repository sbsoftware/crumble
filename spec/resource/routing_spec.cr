require "../spec_helper"

module Crumble::Resource::RoutingSpec
  class MyResource < ::Resource
    layout nil

    def index
      render "Index!"
    end

    def show
      render "Show! #{id}"
    end
  end

  context "with a `GET /my` request" do
    it "should call the #index method" do
      res = String.build do |io|
        orig_ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: "/crumble/resource/routing_spec/my")
        session_store = Crumble::Server::MemorySessionStore(Crumble::Server::Session).new
        ctx = Crumble::Server::RequestContext.new(session_store, orig_ctx)
        MyResource.handle(ctx)
        ctx.response.flush
      end

      res.should contain("Index!")
    end
  end

  context "with a `GET /my/1` request" do
    it "should call the #show method" do
      res = String.build do |io|
        orig_ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: "/crumble/resource/routing_spec/my/1")
        session_store = Crumble::Server::MemorySessionStore(Crumble::Server::Session).new
        ctx = Crumble::Server::RequestContext.new(session_store, orig_ctx)
        MyResource.handle(ctx)
        ctx.response.flush
      end

      res.should contain("Show! 1")
    end
  end
end
