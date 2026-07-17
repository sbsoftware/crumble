require "../spec_helper"

describe TxtFile do
  it "serves text/plain and keeps immutability configurable" do
    immutable = TxtFile.new("/robots-spec.txt", "hello")
    mutable = TxtFile.new("/robots-spec-mutable.txt", "hello", immutable: false)

    immutable.mime_type.should eq("text/plain")
    immutable.uri_path.should match(/\/robots-spec_[a-f0-9]{32}\.txt/)
    mutable.uri_path.should eq("/robots-spec-mutable.txt")
  end
end
