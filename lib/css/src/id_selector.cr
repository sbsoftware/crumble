require "./selector"

module CSS
  class IdSelector < Selector
    @id : CSS::ElementId.class

    def initialize(@id)
    end

    def to_s(io : IO)
      io << "#"
      io << @id
    end
  end
end
