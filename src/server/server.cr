require "../css"
require "../resource"
require "../asset_file"
require "./log_handler"
require "http/server"

class HTTP::Request
  getter id : String = Random.new.hex(8)
end

module Incredible
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
          ([{{Resource.all_subclasses.splat}}] of Resource.class).each do |resource_class|
            break if resource_class.handle(ctx)
          end
        {% end %}
      end

      address = server.bind_tcp "0.0.0.0", 8080
      puts "Listening on http://#{address}"
      server.listen
    end
  end
end
