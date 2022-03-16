require "./call_context"

module JS
  class ExpressionContext < CallContext
    def ==(other)
      ExpressionContext.new("#{self} === #{other}")
    end
  end
end
