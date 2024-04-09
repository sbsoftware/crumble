require "../spec_helper"

module Crumble::Server::SessionUpdateSpec
  class MySession < Session
    property foo : String?
    property blah : Int32?
  end

  describe "MySession#update!" do
    it "should update the given properties" do
      my_session = MySession.new
      my_session.update!(foo: "moo", blah: 3)
      my_session.foo.should eq("moo")
      my_session.blah.should eq(3)
    end

    it "should be able to update only some properties" do
      my_session = MySession.new
      my_session.update!(foo: "goo")
      my_session.foo.should eq("goo")
      my_session.blah.should be_nil
    end

    it "should raise on given attribute that is not defined" do
      my_session = MySession.new
      ex = expect_raises(ArgumentError) do
        my_session.update!(something: "else")
      end
      ex.message.should eq("Not a Session property: [:something]")
    end
  end
end
