require "./selector"

module CSS
  class AnySelector < Selector
    def to_s(io : IO)
      io << "*"
    end
  end
end
