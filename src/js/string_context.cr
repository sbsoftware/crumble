require "./call_context"

module JS
  class StringContext < CallContext
    def ===(other)
      "#{@receiver} === #{other}"
    end

    def includes(other)
      "#{@receiver}.includes(#{other})"
    end

    def toLowerCase
      forward_call(StringContext, "toLowerCase")
    end

    def toUpperCase
      forward_call(StringContext, "toUpperCase")
    end

    def trim
      forward_call(StringContext, "trim")
    end
  end
end
