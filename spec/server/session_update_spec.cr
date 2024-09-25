require "../spec_helper"

module Crumble::Server::SessionUpdateSpec
  describe "MySession#update!" do
    it "should update the given properties" do
      my_session = Session.new
      my_session.update!(foo: "moo", blah: 3)
      my_session.foo.should eq("moo")
      my_session.blah.should eq(3)
    end

    it "should be able to update only some properties" do
      my_session = Session.new
      my_session.update!(foo: "goo")
      my_session.foo.should eq("goo")
      my_session.blah.should be_nil
    end
  end
end
