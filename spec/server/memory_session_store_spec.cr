require "../spec_helper"

describe Crumble::Server::MemorySessionStore do
  it "saves a session and retrieves it again" do
    store = Crumble::Server::MemorySessionStore.new
    session = Crumble::Server::Session.new(store)
    store.set(session)

    store[session.id].should be(session)
  end
end
