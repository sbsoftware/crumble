require "../spec_helper"
require "file_utils"

module Crumble::Server::SessionDecoratorReloadSpec
  describe "SessionDecorator#reload" do
    it "reloads a memoized request context session from memory storage" do
      store = MemorySessionStore.new
      context = TestRequestContext.new(session_store: store)
      context.session.update!(blah: 1)
      updated_session = ::Crumble::Server::Session.new(context.session.id)
      updated_session.update!(blah: 2)
      store.set(updated_session)

      context.session.blah.should eq(1)
      context.session.reload.should be(context.session)
      context.session.blah.should eq(2)
      context.session.session.should be(updated_session)
    end

    it "reloads a memoized request context session from file storage" do
      FileUtils.mkdir_p("/tmp/crumble-session-decorator-reload")
      store = FileSessionStore.new("/tmp/crumble-session-decorator-reload")
      context = TestRequestContext.new(session_store: store)
      context.session.update!(blah: 1)
      updated_session = ::Crumble::Server::Session.new(context.session.id)
      updated_session.update!(blah: 2)
      store.set(updated_session)

      context.session.blah.should eq(1)
      context.session.reload.should be(context.session)
      context.session.blah.should eq(2)
    ensure
      FileUtils.rm_rf("/tmp/crumble-session-decorator-reload")
    end
  end
end
