module CSS
  abstract class CSSClass
    def self.to_s(io : IO)
      io << self.name.dasherize
    end

    def self.selector
      CSS::ClassSelector.new(self)
    end
  end
end
