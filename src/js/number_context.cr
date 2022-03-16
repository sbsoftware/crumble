require "./call_context"
require "./expression_context"

module JS
  class NumberContext < CallContext
    def +(other)
      ExpressionContext.new("#{self} + #{other}")
    end
  end
end
