require "./call_context"

module JS
  class ClassListContext < CallContext
    def add(klass : CSS::CSSClass.class)
      resolve_call("add", klass.to_s.dump)
    end

    def remove(klass : CSS::CSSClass.class)
      resolve_call("remove", klass.to_s.dump)
    end

    def toggle(klass : CSS::CSSClass.class)
      resolve_call("toggle", klass.to_s.dump)
    end
  end
end
