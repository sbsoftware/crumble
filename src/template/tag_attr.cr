class Template
  class TagAttr
    @key : String
    @value : String

    def initialize(@key, @value)
    end

    def html_attr_key
      @key
    end

    def html_attr_value(io : IO)
      io << @value
    end
  end
end
