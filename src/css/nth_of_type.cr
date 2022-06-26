module CSS
  class NthOfType
    @exp : String

    def initialize(exp : Int32)
      @exp = exp.to_s
    end

    def initialize(@exp)
    end

    def to_s(io : IO)
      io << "nth-of-type("
      io << @exp
      io << ")"
    end
  end
end
