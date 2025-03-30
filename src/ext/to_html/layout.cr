{% unless flag?(:release) %}
  require "js"
  require "../../live_reload_resource"

  module ToHtml
    class Layout
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
    end
  end
{% end %}
