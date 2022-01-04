require "./selector"

module CSS
  class CombinedSelector < Selector
    @sel1 : Selector
    @sel2 : Selector

    def initialize(@sel1, @sel2)
    end

    def to_s(io : IO)
      io << @sel1
      io << @sel2
    end
  end
end
