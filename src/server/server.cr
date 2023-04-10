require "../css"
require "../resource"
require "../asset_file"
require "../stimulus/stimulus_controller"
require "./log_handler"
require "http/server"
require "option_parser"

class HTTP::Request
  getter id : String = Random.new.hex(8)
end

module Crumble
  module Server
    extend self

    REQUEST_HANDLERS = [] of Class.class

    macro add_request_handler(klass)
      {% REQUEST_HANDLERS << klass %}
    end

    def start
      port = 8080

      OptionParser.parse do |opts|
        opts.on("-p PORT", "--port PORT", "define port to run server") do |opt|
          port = opt.to_i
        end
      end

      server = HTTP::Server.new([LogHandler.new]) do |ctx|
        req = ctx.request
        res = ctx.response

        next if AssetFile.handle(ctx)
        {% begin %}
          {% for req_handler in REQUEST_HANDLERS %}
            next if {{req_handler}}.handle(ctx)
          {% end %}
        {% end %}

        {% begin %}
          {% for resource_class in Resource.all_subclasses %}
            {% if !resource_class.abstract? %}
              next if {{resource_class}}.handle(ctx)
            {% end %}
          {% end %}
        {% end %}

        res.print "Not Found"
        res.status_code = 404
      end

      unless ENV.fetch("CRUMBLE_ORM_MIGRATION", "").in?(["0", "false"])
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
