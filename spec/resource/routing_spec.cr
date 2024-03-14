require "../spec_helper"

module Crumble::Resource::RoutingSpec
  class MyResource < Resource
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
        ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: "/crumble/resource/routing_spec/my")
        MyResource.handle(ctx)
        ctx.response.flush
      end

      res.should contain("Index!")
    end
  end

  context "with a `GET /my/1` request" do
    it "should call the #show method" do
      res = String.build do |io|
        ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: "/crumble/resource/routing_spec/my/1")
        MyResource.handle(ctx)
        ctx.response.flush
      end

      res.should contain("Show! 1")
    end
  end
end
