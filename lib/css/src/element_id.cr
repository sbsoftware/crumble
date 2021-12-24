module CSS
  abstract class ElementId
    def self.to_s(io : IO)
      io << self.name.dasherize
    end

    def self.selector
      CSS::IdSelector.new(self)
    end
  end
end
