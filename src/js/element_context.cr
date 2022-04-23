require "./call_context"
require "./class_list_context"

module JS
  class ElementContext < CallContext
    def value
      resolve_attr("value")
    end

    def innerHTML
      resolve_attr("innerHTML")
    end

    def outerHTML=(new_html)
      resolve_assignment("outerHTML", new_html)
    end

    def classList
      forward(ClassListContext, "classList")
    end

    def dataset
      resolve_attr("dataset")
    end
  end
end
