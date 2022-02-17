require "./call_context"
require "./string_context"

module JS
  class ResponseTextPromiseContext < CallContext
    def then
      resolve_call("then", "function(text) {\n#{yield StringContext.new("text")}\n}")
    end
  end
end
