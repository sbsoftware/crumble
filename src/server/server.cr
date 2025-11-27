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

    @@port : Int32?

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
      server = HTTP::Server.new(middlewares)

      address = server.bind_tcp "0.0.0.0", port
      # Save the bound port so later calls (e.g. host) report the actual listening port,
      # including cases where the user asked for port 0 and the OS picked an ephemeral one.
      @@port = address.port
      puts "Listening on http://#{address}"
      server.listen
    end

    def host : String
      # Prefer explicit override, otherwise derive a self-documenting local URL using the real port.
      ENV.fetch("CRUMBLE_HOST") { "http://localhost:#{port}" }
    end

    def port : Int32
      # If we already bound, keep using that port instead of re-running option parsing.
      return @@port.not_nil! if @@port

      OptionParser.parse do |opts|
        opts.on("-p PORT", "--port PORT", "define port to run server") do |opt|
          @@port = opt.to_i
        end
      end

      @@port || 8080
    end
  end
end
