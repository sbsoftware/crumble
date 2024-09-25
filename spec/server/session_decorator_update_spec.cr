require "../spec_helper"

module Crumble::Server::SessionDecoratorUpdateSpec
  describe "SessionDecorator#update!" do
    it "should persist the changes in the session store" do
      store = MemorySessionStore.new
      my_session = ::Crumble::Server::Session.new
      decorator = SessionDecorator.new(store, my_session)
      decorator.update!(foo: "boo", blah: 2)
      session_2 = store[my_session.id]
      session_2.foo.should eq("boo")
      session_2.blah.should eq(2)
    end
  end
end
