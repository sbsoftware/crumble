require "../css"
require "../resource"
require "../asset_file"
require "../stimulus/stimulus_controller"
require "./log_handler"
require "http/server"

class HTTP::Request
  getter id : String = Random.new.hex(8)
end

module Crrumble
  module Server
    extend self

    def start
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

      address = server.bind_tcp "0.0.0.0", 8080
      puts "Listening on http://#{address}"
      server.listen
    end
  end
end
