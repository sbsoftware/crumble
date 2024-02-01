require "../spec_helper"

describe LogHandler do
  context "#call" do
    context "when called with an X-Forwarded-For header" do
      it "should output it as the remote IP" do
        headers = HTTP::Headers.new
        headers["X-Forwarded-For"] = "123.234.12.0"
        ctx = Crumble::Server::TestRequestContext.new(
          id: "abcdefg",
          resource: "/",
          method: "GET",
          remote_address: "192.168.1.1",
          headers: headers
        )

        output = String.build do |io|
          LogHandler.new(io).call(ctx)
        end

        output.should match(/abcdefg/)
        output.should match(/123.234.12.0 GET \//)
      end
    end

    context "when called without an X-Forwarded-For header" do
      it "should output the original remote IP" do
        headers = HTTP::Headers.new
        ctx = Crumble::Server::TestRequestContext.new(
          id: "abcdefg",
          resource: "/",
          method: "GET",
          remote_address: "192.168.1.1",
          headers: headers
        )

        output = String.build do |io|
          LogHandler.new(io).call(ctx)
        end

        output.should match(/abcdefg/)
        output.should match(/192.168.1.1:80 GET \//)
      end
    end
  end
end
