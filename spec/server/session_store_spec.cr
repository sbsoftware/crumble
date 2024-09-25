require "../spec_helper"

module Crumble::Server::SessionStoreSpec
  class TestSession < Crumble::Server::Session
    include Crumble::Server::Session::Timestamps
  end

  describe "#set" do
    it "sets #created_at" do
      store = Crumble::Server::MemorySessionStore.new
      session = TestSession.new
      session.created_at.should be_nil
      store.set(session)

      session2 = store[session.id].as(TestSession)
      session2.created_at.should_not be_nil
    end

    it "doesn't overwrite #created_at" do
      store = Crumble::Server::MemorySessionStore.new
      session = TestSession.new
      now = Time.utc
      session.update!(created_at: now)
      store.set(session)

      session2 = store[session.id].as(TestSession)
      session2.created_at.should eq(now)
    end

    it "overwrites #updated_at" do
      store = Crumble::Server::MemorySessionStore.new
      session = TestSession.new
      now = Time.utc
      session.update!(updated_at: now)
      store.set(session)

      session2 = store[session.id].as(TestSession)
      session2.updated_at.not_nil!.should be > now
    end
  end
end
