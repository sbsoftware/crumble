require "../../context_view"

{% unless flag?(:release) %}
  require "js"
  require "../../live_reload_resource"
{% end %}

module ToHtml
  class Layout
    include Crumble::ContextView

    def window_title
      ctx.handler.window_title
    end

    class OpenGraphMeta
      include Crumble::ContextView

      template do
        handler = ctx.handler

        if title = handler.og_title
          meta property: "og:title", content: title
        end

        if description = handler.og_description
          meta property: "og:description", content: description
        end

        if image = handler.og_image
          meta property: "og:image", content: image
        end

        if url = handler.og_url
          meta property: "og:url", content: url
        end

        if type = handler.og_type
          meta property: "og:type", content: type
        end

        if site_name = handler.og_site_name
          meta property: "og:site_name", content: site_name
        end
      end
    end

    append_to_head OpenGraphMeta.new(ctx: ctx)

    {% unless flag?(:release) %}
      class LiveReloadScript < JS::Code
        def_to_js do
          pageload_time = Date.now._call

          evt_source = EventSource.new(LiveReloadResource.uri_path.to_js_ref)

          evt_source.addEventListener("message") do |msg|
            compile_time = Date.parse(msg.data)

            if pageload_time < compile_time
              window.location.reload._call
            end
          end
        end
      end

      append_to_head LiveReloadScript
    {% end %}
  end
end
