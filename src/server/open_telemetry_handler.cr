require "http/server/handler"
require "opentelemetry-sdk"

module Crumble::Server
  class OpenTelemetryHandler
    include HTTP::Handler

    def call(context)
      generic_path = context.request.path.gsub(/\/\d+(?=$|\/)/, "/:id")
      span_name = "#{context.request.method} #{generic_path}"
      OpenTelemetry.tracer.in_span(span_name) do |span|
        span["deployment.environment.name"] = ENV.fetch("CRUMBLE_ENV", "dev")
        span["http.method"] = context.request.method
        span["http.path"] = context.request.path

        begin
          call_next(context)
        ensure
          span["http.status_code"] = context.response.status_code.to_i64
        end
      end
    end
  end
end
