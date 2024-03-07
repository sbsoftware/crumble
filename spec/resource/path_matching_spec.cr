require "../spec_helper"

module Crumble::Resource::PathMatchingSpec
  class RootResource < Resource
    def self.root_path
      "/"
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
end
