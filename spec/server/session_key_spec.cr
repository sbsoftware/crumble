require "../spec_helper"

describe Crumble::Server::SessionKey do
  context ".new" do
    it "returns a new instance" do
      uuid = UUID.random
      session_key = Crumble::Server::SessionKey.new(uuid)
      session_key.to_s.should eq(uuid.to_s)
    end
  end

  context ".generate" do
    it "returns a new instance" do
      session_key = Crumble::Server::SessionKey.generate
      session_key.to_s.should_not be_empty
    end
  end
end
