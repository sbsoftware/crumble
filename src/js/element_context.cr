require "./call_context"
require "./class_list_context"

module JS
  class ElementContext < CallContext
    def ==(other)
      "#{@receiver} === #{other}"
    end

    def !=(other)
      "#{@receiver} != #{other}"
    end

    def value
      forward(StringContext, "value")
    end

    def value=(new_value)
      resolve_assignment("value", new_value)
    end

    def innerHTML
      resolve_attr("innerHTML")
    end

    def innerHTML=(new_html)
      resolve_assignment("innerHTML", new_html)
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

    def click
      resolve_call("click")
    end

    def children
      ArrayContext(ElementContext).new("Array.from(#{receiver_dot("children")})")
    end

    def textContent
      forward(StringContext, "textContent")
    end
  end
end
