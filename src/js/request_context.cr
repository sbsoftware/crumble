require "./call_context"

module JS
  class RequestContext < CallContext
    def method
      forward(StringContext, "method")
    end
  end
end
