require "./selector"
require "./pseudoclass"

module CSS
  class PseudoclassSelector < Selector
    @element_selector : Selector
    @pseudoclass : CSS::Pseudoclass

    def initialize(@element_selector, @pseudoclass)
    end

    def to_s(io : IO)
      io << @element_selector
      io << "::"
      io << @pseudoclass
    end
  end
end
