require "../spec_helper"
require "file_utils"

describe Crumble::Server::FileSessionStore do
  before_each do
    FileUtils.mkdir("spec/tmp")
  end

  after_each do
    FileUtils.rm_r("spec/tmp")
  end

  it "saves a session and retrieves it again" do
    store = Crumble::Server::FileSessionStore.new("spec/tmp")
    session = Crumble::Server::Session.new
    store.set(session)

    store.has_key?(session.id).should be_true

    new_session = store[session.id]
    new_session.should_not be(session)
    new_session.id.to_s.should eq(session.id.to_s)
  end
end
