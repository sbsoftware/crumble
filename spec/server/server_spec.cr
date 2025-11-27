require "../spec_helper"

module Crumble::Server
  def self.set_port_for_spec(port : Int32?)
    @@port = port
  end
end

describe Crumble::Server do
  describe ".host" do
    around_each do |example|
      original_argv = ARGV.dup
      ENV.delete("CRUMBLE_HOST")
      Crumble::Server.set_port_for_spec(nil)

      begin
        example.run
      ensure
        ENV.delete("CRUMBLE_HOST")
        Crumble::Server.set_port_for_spec(nil)
        ARGV.clear
        original_argv.each { |arg| ARGV << arg }
      end
    end

    it "returns CRUMBLE_HOST when it is set" do
      ENV["CRUMBLE_HOST"] = "https://example.test"

      Crumble::Server.host.should eq("https://example.test")
    end

    it "uses the configured port when env variable is missing" do
      Crumble::Server.set_port_for_spec(9000)

      Crumble::Server.host.should eq("http://localhost:9000")
    end

    it "falls back to the default port when none is configured" do
      ARGV.clear

      Crumble::Server.host.should eq("http://localhost:8080")
    end
  end
end
