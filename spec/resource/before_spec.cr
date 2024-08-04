require "../spec_helper"

module Crumble::Resource::BeforeSpec
  class Parent < Crumble::Resource
    before do
      if id?
        true
      else
        false
      end
    end
  end

  class Res1 < Parent
    before(:show) do
      true
    end

    before(:show) do
      403
    end

    def show
      raise "This should not be reached!"
    end

    def index
      raise "This should not be reached!"
    end
  end

  class Res2 < Parent
    def index
      raise "This should not be reached!"
    end

    def show
      render "Success!"
    end
  end

  describe "Res1#index" do
    it "should not be reached" do
      ctx = Crumble::Server::TestRequestContext.new(resource: Res1.uri_path)
      Res1.handle(ctx).should eq(true)
      ctx.response.status_code.should eq(400)
    end
  end

  describe "Res1#show" do
    it "should not be reached" do
      ctx = Crumble::Server::TestRequestContext.new(resource: Res1.uri_path(2))
      Res1.handle(ctx).should eq(true)
      ctx.response.status_code.should eq(403)
    end
  end

  describe "Res2#index" do
    it "should not be reached" do
      ctx = Crumble::Server::TestRequestContext.new(resource: Res2.uri_path)
      Res2.handle(ctx).should eq(true)
      ctx.response.status_code.should eq(400)
    end
  end

  describe "Res2#show" do
    it "should be reached" do
      response = String.build do |res_io|
        ctx = Crumble::Server::TestRequestContext.new(response_io: res_io, resource: Res2.uri_path(3))
        Res2.handle(ctx).should eq(true)
        ctx.response.status_code.should eq(200)
        ctx.response.flush
      end
      response.should contain("Success!")
    end
  end
end
