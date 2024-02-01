require "../css"
require "../resource"
require "../asset_file"
require "./root_request_handler"
require "./session"
require "./memory_session_store"
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

      request_handler = RootRequestHandler.new(MemorySessionStore(Crumble::Server::Session).new)
      server = HTTP::Server.new([LogHandler.new(STDOUT), request_handler])

      if ENV.fetch("CRUMBLE_ORM_MIGRATION", "").in?(["1", "true"])
        {% for orm_class in Crumble::ORM::Base.all_subclasses %}
          puts "Creating table for #{{{orm_class.id}}}"
          {{orm_class.id}}.ensure_table_exists!
        {% end %}
      end

      address = server.bind_tcp "0.0.0.0", port
      puts "Listening on http://#{address}"
      server.listen
    end
  end
end
