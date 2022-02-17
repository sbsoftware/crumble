require "./call_context"

module JS
  class FetchResponseContext < CallContext
    def text
      forward_call(ResponseTextPromiseContext, "text")
    end
  end
end
