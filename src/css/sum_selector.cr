require "./selector"

module CSS
  class SumSelector < Selector
    @selectors : Array(Selector)

    def initialize(@selectors)
    end

    def to_s(io : IO)
      io << @selectors.join(", ")
    end
  end
end 
