require "./call_context"
require "./navigator_context"
require "./console_context"
require "./fetch_promise_context"

module JS
  class WindowContext < CallContext
    def window
      forward(WindowContext, "window")
    end

    def navigator
      forward(NavigatorContext, "navigator")
    end

    def console
      forward(ConsoleContext, "console")
    end

    def debugger
      resolve_attr("debugger")
    end

    def fetch(uri, method, headers = {} of String => String)
      forward_call(FetchPromiseContext, "fetch", uri, js_object({method: method, headers: headers}))
    end

    def fetch(request)
      forward_call(FetchPromiseContext, "fetch", request)
    end

    def addEventListener(event : JavascriptEvent.class)
      resolve_call("addEventListener", event.to_s.dump, "function(e) {\n#{yield EventContext.new("e")}\n}")
    end
  end
end
