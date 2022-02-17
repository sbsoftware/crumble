require "./call_context"
require "./window_context"

module JS
  class ServiceWorkerContext < WindowContext
    def _self
      forward(ServiceWorkerSelfContext, "self")
    end
  end
end
