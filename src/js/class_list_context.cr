require "./call_context"

module JS
  class ClassListContext < CallContext
    def toggle(klass : CSS::CSSClass.class)
      resolve_call("toggle", klass.to_s.dump)
    end
  end
end
