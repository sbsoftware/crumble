class Template
  enum Method
    Get
    Post
    Put
    Patch

    def to_s(io)
      io << self.to_s.upcase
    end

    def html_attr_key
      "method"
    end

    def html_attr_value(io)
      io << self
    end
  end
end
