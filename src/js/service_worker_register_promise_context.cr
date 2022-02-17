require "./call_context"

module JS
  class ServiceWorkerRegisterPromiseContext < CallContext
    def then
      resolve_call("then", "function(_reg) {\n#{yield ServiceWorkerRegistrationContext.new("_reg")}\n}")
    end
  end
end
