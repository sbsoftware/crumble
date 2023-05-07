require "http/server/handler"
require "./request_context"

class Crumble::Server::RootRequestHandler(S)
  include HTTP::Handler

  REQUEST_HANDLERS = [] of Class.class

  macro add_request_handler(rh)
    {% REQUEST_HANDLERS << rh %}
  end

  getter session_store : S

  def initialize(@session_store)
  end

  def call(original_ctx : HTTP::Server::Context)
    ctx = RequestContext.new(session_store, original_ctx)

    return if AssetFile.handle(ctx)

    {% begin %}
      {% for request_handler in REQUEST_HANDLERS %}
        return if {{request_handler}}.handle(ctx)
      {% end %}
    {% end %}
    {% begin %}
      {% for resource_class in Resource.all_subclasses %}
        {% if !resource_class.abstract? %}
          return if {{resource_class}}.handle(ctx)
        {% end %}
      {% end %}
    {% end %}

    ctx.response.print "Not Found"
    ctx.response.status_code = 404
  end
end
