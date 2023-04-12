require "./call_context"

module JS
  class ArrayContext(T) < CallContext
    def each
      resolve_call("forEach", "(item) => {\n#{yield T.new("item")}\n}")
    end
  end
end
