require "./call_context"

module JS
  class NavigatorServiceWorkerContext < CallContext
    def register(path)
      forward_call(ServiceWorkerRegisterPromiseContext, "register", path.dump)
    end
  end
end
