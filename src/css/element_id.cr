module CSS
  abstract class ElementId
    def self.to_s(io : IO)
      io << self.name.dasherize
    end

    def self.selector
      CSS::IdSelector.new(self)
    end

    def self.to_tag_attr
      {"id", self}
    end
  end
end
