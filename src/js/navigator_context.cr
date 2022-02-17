require "./call_context"
require "./service_worker_context"

module JS
  class NavigatorContext < CallContext
    def serviceWorker
      forward(NavigatorServiceWorkerContext, "serviceWorker")
    end
  end
end
