require "./root_request_handler"
require "./session"
require "./memory_session_store"
require "./file_session_store"
require "./log_handler"
require "http/server"
require "option_parser"

class HTTP::Request
  getter id : String = Random.new.hex(8)
end

module Crumble
  module Server
    extend self

    def start
      port = 8080

      OptionParser.parse do |opts|
        opts.on("-p PORT", "--port PORT", "define port to run server") do |opt|
          port = opt.to_i
        end
      end

      request_handler = RootRequestHandler.new
      server = HTTP::Server.new([LogHandler.new(STDOUT), request_handler])

      address = server.bind_tcp "0.0.0.0", port
      puts "Listening on http://#{address}"
      server.listen
    end
  end
end
