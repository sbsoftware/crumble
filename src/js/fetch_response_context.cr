require "./call_context"

module JS
  class FetchResponseContext < CallContext
    def text
      forward_call(ResponseTextPromiseContext, "text")
    end

    def json
      forward_call(ResponseJsonPromiseContext, "json")
    end

    def clone
      forward_call(self.class, "clone")
    end
  end
end
