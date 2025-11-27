module CSS
  class Class
    def self.to_html_attrs(_tag, attrs)
      attrs["class"] = to_s
    end
  end
end
