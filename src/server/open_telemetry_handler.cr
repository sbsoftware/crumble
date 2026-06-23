require "http/server/handler"
require "opentelemetry-sdk"
require "uri"

module Crumble::Server
  class OpenTelemetryHandler
    include HTTP::Handler

    def call(context)
      generic_path = context.request.path.gsub(/\/\d+(?=$|\/)/, "/:id")
      span_name = "#{context.request.method} #{generic_path}"
      OpenTelemetry.tracer.in_span(span_name) do |span|
        # Span kind "server"
        span.server!

        span["deployment.environment.name"] = ENV.fetch("CRUMBLE_ENV", "dev")
        span["http.request.method"] = context.request.method
        span["http.route"] = generic_path
        span["url.path"] = context.request.path
        span["url.scheme"] = url_scheme(context.request)
        span["server.address"] = server_address(context.request)
        span["server.port"] = server_port(context.request).to_i64
        span["network.protocol.name"] = "http"
        span["network.protocol.version"] = context.request.version.starts_with?("HTTP/") ? context.request.version[5..] : context.request.version
        span["user_agent.original"] = context.request.headers["User-Agent"] if context.request.headers.has_key?("User-Agent")
        span["client.address"] = client_address(context.request) if context.request.remote_address

        begin
          call_next(context)
        ensure
          span["http.response.status_code"] = context.response.status_code.to_i64
        end
      end
    end

    private def url_scheme(request)
      request.headers["X-Forwarded-Proto"]?.try(&.split(",").first.strip) || configured_host_uri.try(&.scheme) || "http"
    end

    private def server_address(request)
      request.hostname || configured_host_uri.try(&.hostname) || "localhost"
    end

    private def server_port(request)
      request_host_uri(request).try(&.port) || request.local_address.try { |address| address.as?(Socket::IPAddress).try(&.port) } || configured_host_uri.try(&.port) || Crumble::Server.port
    end

    private def client_address(request)
      case remote_address = request.remote_address
      when Socket::IPAddress
        remote_address.address
      else
        remote_address.to_s
      end
    end

    private def request_host_uri(request)
      URI.parse("http://#{request.headers["Host"]}") if request.headers.has_key?("Host")
    rescue URI::Error
      nil
    end

    private def configured_host_uri
      URI.parse(Crumble::Server.host)
    rescue URI::Error
      nil
    end
  end
end
