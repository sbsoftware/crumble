require "../spec_helper"

module Crumble::Resource::RedirectBackSpec
  class HomeResource < Resource
    def self.root_path
      "/"
    end
  end

  class MyResource < Resource
    def create
      redirect_back fallback_path: HomeResource.uri_path
    end
  end

  context "with a referrer header" do
    it "should set location to the value of the header" do
      headers = HTTP::Headers.new
      headers["Referer"] = "/somewhere/else"
      ctx = Crumble::Server::TestRequestContext.new(resource: MyResource.uri_path, method: "POST", headers: headers)
      MyResource.handle(ctx)

      ctx.response.status_code.should eq(303)
      ctx.response.headers["Location"].should eq("/somewhere/else")
    end
  end

  context "with no referrer header" do
    it "should set location to the fallback path" do
      ctx = Crumble::Server::TestRequestContext.new(resource: MyResource.uri_path, method: "POST")
      MyResource.handle(ctx)

      ctx.response.status_code.should eq(303)
      ctx.response.headers["Location"].should eq("/")
    end
  end
end
