module CSS
  abstract class ElementId
    def self.to_s(io : IO)
      io << self.name.dasherize
    end

    def self.selector
      CSS::IdSelector.new(self)
    end

    def self.html_attr_key
      "id"
    end

    def self.html_attr_value(io)
      io << self
    end
  end
end
