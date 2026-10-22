require "./spec_helper"

describe "generated Dockerfile" do
  dockerfile = File.read(Path[__DIR__, "..", "src", "cli", "templates", "Dockerfile"])
  cli = File.read(Path[__DIR__, "..", "src", "cli.cr"])

  it "uses Crystal 1.20 with the development dependencies" do
    dockerfile.should eq("FROM crystallang/crystal:1.20\n\nRUN apt-get update && apt-get install -y watchexec libsqlite3-dev\n")
  end

  it "is created by the init command" do
    cli.should contain("ensure_file(\"Dockerfile\", {{read_file")
  end
end
