module CSS
  class ElementId
    def self.to_html_attrs(tag, attrs)
      case tag
      when "label"
        attrs["for"] = to_s
      else
        attrs["id"] = to_s
      end
    end
  end
end
