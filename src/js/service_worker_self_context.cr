require "./call_context"

module JS
  class ServiceWorkerSelfContext < CallContext
    def addEventListener(event_class : JavascriptEvent.class)
      resolve_call("addEventListener", event_class.to_s.dump, "function(e) {\n#{yield event_class.new("e")}\n}")
    end
  end
end
