require "./selector"

module CSS
  class AttrSelector < Selector
    @name : String
    @value : String

    def initialize(@name, @value)
    end

    def to_s(io : IO)
      io << "["
      io << @name
      io << "='"
      io << @value
      io << "']"
    end
  end
end
