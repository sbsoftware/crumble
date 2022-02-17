require "./call_context"

module JS
  class ConsoleContext < CallContext
    alias Loggable = String | CallContext

    def log(*entries : Loggable)
      resolve_call("log", *entries)
    end
  end
end
