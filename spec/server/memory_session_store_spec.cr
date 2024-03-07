require "../spec_helper"

module MemorySessionStoreTest
  class MySession < Crumble::Server::Session
    getter user_id : Int64

    def initialize(@id, @user_id); end
  end
end

describe Crumble::Server::MemorySessionStore do
  it "saves a session and retrieves it again" do
    store = Crumble::Server::MemorySessionStore.new
    session_key = Crumble::Server::SessionKey.generate
    user_id = 12345
    session = MemorySessionStoreTest::MySession.new(session_key, user_id)
    store.set(session)

    store[session_key].should be(session)
  end
end
