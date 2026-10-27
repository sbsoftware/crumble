require "./spec_helper"

describe "generated Dockerfile" do
  dockerfile = File.read(Path[__DIR__, "..", "src", "cli", "templates", "Dockerfile"])
  cli = File.read(Path[__DIR__, "..", "src", "cli.cr"])

  it "uses Crystal 1.20 with the development dependencies" do
    dockerfile.should start_with("FROM crystallang/crystal:1.20\n")
    dockerfile.should contain("apt-get install -y curl libsqlite3-dev")
    dockerfile.should contain("ARG WATCHEXEC_VERSION=2.3.2")
    dockerfile.should contain("amd64) echo x86_64 ;; arm64) echo aarch64")
    dockerfile.should contain("github.com/watchexec/watchexec/releases/download")
    dockerfile.should contain("dpkg -i watchexec.deb")
  end

  it "is created by the init command" do
    cli.should contain("ensure_file(\"Dockerfile\", {{read_file")
  end
end
