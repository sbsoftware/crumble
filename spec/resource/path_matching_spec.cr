require "../spec_helper"

module Crumble::Resource::PathMatchingSpec
  class RootResource < Resource
    root_path "/"
  end

  class PageStyleResource < Resource
    root_path "/accounts"
    path_param account_id
    path_param slug, /[a-z0-9-]+/
    nested_path "posts"
    nested_path "details"

    def index
      render "account_id=#{account_id} slug=#{slug}"
    end
  end

  class NestedMemberResource < Resource
    root_path "/nested-members"
    path_param id
    nested_path "details"

    def index
      render "nested id=#{id}"
    end
  end

  describe "RootResource.match" do
    it "should match on /" do
      RootResource.match("/").should be_truthy
    end

    it "should not match on any other path ending on /" do
      RootResource.match("/test/").should be_falsey
    end
  end

  describe "PageStyleResource.match" do
    it "supports the same path matching declarations as pages" do
      PageStyleResource.uri_path(account_id: 123, slug: "hello-world").should eq("/accounts/123/hello-world/posts/details")
      PageStyleResource.match("/accounts/123/hello-world/posts/details").should be_truthy
      PageStyleResource.match("/accounts/123/hello_world/posts/details").should be_falsey
    end

    it "exposes declared path params while handling requests" do
      response = String.build do |io|
        ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: PageStyleResource.uri_path(account_id: 123, slug: "hello-world"))
        PageStyleResource.handle(ctx).should eq(true)
        ctx.response.flush
      end

      response.should contain("account_id=123 slug=hello-world")
    end
  end

  describe "NestedMemberResource.match" do
    it "does not match the parent member path without the nested component" do
      NestedMemberResource.match(NestedMemberResource.uri_path(id: 7)).should be_truthy
      NestedMemberResource.match("/nested-members/7").should be_falsey
      NestedMemberResource.match("/nested-members").should be_falsey
    end
  end
end
