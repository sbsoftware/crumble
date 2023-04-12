module CSS
  abstract class CSSClass
    def self.to_s(io : IO)
      io << self.name.gsub("::", "--").dasherize
    end

    def self.selector
      CSS::ClassSelector.new(self)
    end

    def self.to_tag_attr
      {"class", self}
    end
  end
end
