require "http/server/handler"
require "./request_context"
require "../asset_file"
require "../page"
require "../resource"

class Crumble::Server::RootRequestHandler
  include HTTP::Handler

  REQUEST_HANDLERS = [] of Class.class

  macro add_request_handler(rh)
    {% REQUEST_HANDLERS << rh %}
  end

  def call(context : HTTP::Server::Context)
    ctx = RequestContext.new(context)

    return if AssetFileRegistry.handle(ctx)

    {% begin %}
      {% for page_class in Page.all_subclasses %}
        {% if !page_class.abstract? %}
          return if {{page_class}}.handle(ctx)
        {% end %}
      {% end %}
    {% end %}
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
