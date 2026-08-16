require "../spec_helper"
require "file_utils"

describe Crumble::Server::FileSessionStore do
  before_each do
    FileUtils.mkdir("spec/tmp")
  end

  after_each do
    FileUtils.rm_rf("spec/tmp")
  end

  it "creates a missing directory and saves a session with a supplied ID" do
    session_id = Crumble::Server::SessionKey.generate
    store = Crumble::Server::FileSessionStore.new("spec/tmp/sessions")
    Dir.exists?("spec/tmp/sessions").should be_true

    session = Crumble::Server::Session.new(session_id)
    store.set(session)

    store.has_key?(session_id).should be_true
    store[session_id].id.should eq(session_id)
  end

  it "saves and retrieves a new session in an existing directory" do
    store = Crumble::Server::FileSessionStore.new("spec/tmp")
    session = Crumble::Server::Session.new
    store.set(session)

    store.has_key?(session.id).should be_true

    new_session = store[session.id]
    new_session.should_not be(session)
    new_session.id.to_s.should eq(session.id.to_s)
  end
end
