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
          {% for style_class in CSS::Stylesheet.all_subclasses %}
          if req.path == {{style_class}}.uri_path
            res.content_type = "text/css"
            res.print {{style_class}}
            next
          end
          {% end %}
        {% end %}
        {% begin %}
          {% for resource_class in Resource.all_subclasses %}
            next if {{resource_class}}.handle(ctx)
          {% end %}
        {% end %}

        res.print "Not Found"
        res.status_code = 404
      end

      address = server.bind_tcp "0.0.0.0", port
      puts "Listening on http://#{address}"
      server.listen
    end
  end
end
