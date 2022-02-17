require "./call_context"

module JS
  class StringContext < CallContext
    def ===(other)
      "#{@receiver} === #{other}"
    end
  end
end
