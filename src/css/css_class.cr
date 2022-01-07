module CSS
  abstract class CSSClass
    def self.to_s(io : IO)
      io << self.name.dasherize
    end

    def self.selector
      CSS::ClassSelector.new(self)
    end

    def self.html_attr_key
      "class"
    end

    def self.html_attr_value(io)
      io << self
    end
  end
end
