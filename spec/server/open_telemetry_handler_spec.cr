require "../spec_helper"
require "json"

describe Crumble::Server::OpenTelemetryHandler do
  it "sets OpenTelemetry HTTP server span attributes" do
    memory = IO::Memory.new
    previous_config = OpenTelemetry.config
    request = Crumble::Server::TestRequest.new(resource: "/widgets/123/edit?tab=details", method: "POST", remote_address: "203.0.113.8", headers: HTTP::Headers{"Host" => "example.test:8443", "User-Agent" => "crumble-spec/1.0", "X-Forwarded-Proto" => "https"})
    request.local_address = Socket::IPAddress.new("10.0.0.10", 8080)
    context = HTTP::Server::Context.new(request, Crumble::Server::TestResponse.new)
    handler = Crumble::Server::OpenTelemetryHandler.new
    handler.next = ->(ctx : HTTP::Server::Context) { ctx.response.status_code = 204; nil }

    begin
      OpenTelemetry.configure do |config|
        config.exporter = OpenTelemetry::Exporter.new(variant: :io, io: memory)
      end

      handler.call(context)
      10.times do
        break if memory.size > 0
        sleep 10.milliseconds
      end

      memory.rewind
      span = JSON.parse(memory.gets_to_end)["spans"][0]
      attributes = span["attributes"]

      span["name"].as_s.should eq("POST /widgets/:id/edit")
      attributes["deployment.environment.name"].as_s.should eq(ENV.fetch("CRUMBLE_ENV", "dev"))
      attributes["http.request.method"].as_s.should eq("POST")
      attributes["http.route"].as_s.should eq("/widgets/:id/edit")
      attributes["url.path"].as_s.should eq("/widgets/123/edit")
      attributes["url.scheme"].as_s.should eq("https")
      attributes["server.address"].as_s.should eq("example.test")
      attributes["server.port"].as_i.should eq(8443)
      attributes["network.protocol.name"].as_s.should eq("http")
      attributes["network.protocol.version"].as_s.should eq("1.1")
      attributes["user_agent.original"].as_s.should eq("crumble-spec/1.0")
      attributes["client.address"].as_s.should eq("203.0.113.8")
      attributes["http.response.status_code"].as_i.should eq(204)
      attributes.as_h.has_key?("http.method").should be_false
      attributes.as_h.has_key?("http.path").should be_false
      attributes.as_h.has_key?("http.status_code").should be_false
    ensure
      OpenTelemetry.config = previous_config
      OpenTelemetry.provider.configure!(previous_config)
    end
  end
end
