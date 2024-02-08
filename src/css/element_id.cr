module CSS
  abstract class ElementId
    def self.to_s(io : IO)
      io << self.name.gsub("::", "--").dasherize
    end

    def self.selector
      CSS::IdSelector.new(self)
    end

    def self.to_html_attrs(tag, attrs)
      case tag
      when "label"
        attrs["for"] = self.to_s
      else
        attrs["id"] = self.to_s
      end
    end
  end
end
