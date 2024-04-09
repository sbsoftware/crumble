require "../spec_helper"

module Crumble::Server::SessionUpdateSpec
  class MySession < Session
    property foo : String?
    property blah : Int32?
  end

  describe "MySession#update!" do
    it "should update the given properties" do
      store = MemorySessionStore.new
      my_session = MySession.new(store)
      my_session.update!(foo: "moo", blah: 3)
      my_session.foo.should eq("moo")
      my_session.blah.should eq(3)
    end

    it "should persist the changes in the session store" do
      store = MemorySessionStore.new
      my_session = MySession.new(store)
      my_session.update!(foo: "boo", blah: 2)
      session_2 = store[my_session.id].as(MySession)
      session_2.foo.should eq("boo")
      session_2.blah.should eq(2)
    end

    it "should be able to update only some properties" do
      store = MemorySessionStore.new
      my_session = MySession.new(store)
      my_session.update!(foo: "goo")
      my_session.foo.should eq("goo")
      my_session.blah.should be_nil
    end

    it "should raise on given attribute that is not defined" do
      store = MemorySessionStore.new
      my_session = MySession.new(store)
      ex = expect_raises(ArgumentError) do
        my_session.update!(something: "else")
      end
      ex.message.should eq("Not a Session property: [:something]")
    end
  end
end
