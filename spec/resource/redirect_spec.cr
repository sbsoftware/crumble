require "../spec_helper"

module Crumble::Resource::RedirectSpec
  class MyResource < Resource
    def create
      redirect self.class.uri_path(1)
    end
  end

  context "with a `POST /my` request" do
    it "should set correct status code and location header" do
      ctx = Crumble::Server::TestRequestContext.new(resource: "/crumble/resource/redirect_spec/my", method: "POST")
      MyResource.handle(ctx)

      ctx.response.status_code.should eq(303)
      ctx.response.headers["Location"].should eq("/crumble/resource/redirect_spec/my/1")
    end
  end
end
