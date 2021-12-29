require "./selector"

module CSS
  class ClassSelector < Selector
    @klass : CSS::CSSClass.class

    def initialize(@klass)
    end

    def to_s(io : IO)
      io << "."
      io << @klass
    end
  end
end
