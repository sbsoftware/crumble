require "./call_context"
require "./fetch_response_context"

module JS
  class FetchPromiseContext < CallContext
    def then
      resolve_call("then", "function(res) {\n#{yield FetchResponseContext.new("res")}\n}")
    end
  end
end
