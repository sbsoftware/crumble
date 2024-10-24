require "./root_request_handler"
require "./log_handler"
require "./open_telemetry_handler"
require "http/server"
require "option_parser"

class HTTP::Request
  getter id : String = Random.new.hex(8)
end

module Crumble
  module Server
    extend self

    def log_middleware
      LogHandler.new(STDOUT)
    end

    def open_telemetry_handler
      OpenTelemetryHandler.new
    end

    def middlewares
      [log_middleware, open_telemetry_handler, RootRequestHandler.new].compact
    end

    def start
      port = 8080

      OptionParser.parse do |opts|
        opts.on("-p PORT", "--port PORT", "define port to run server") do |opt|
          port = opt.to_i
        end
      end

      server = HTTP::Server.new(middlewares)

      address = server.bind_tcp "0.0.0.0", port
      puts "Listening on http://#{address}"
      server.listen
    end
  end
end
