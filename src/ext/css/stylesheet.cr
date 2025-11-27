require "../../asset_file/css_file"

module CSS
  class Stylesheet
    macro inherited
      @@asset_file : CssFile = CssFile.new("/styles/#{self.name.underscore.gsub("::", "__")}.css", self.to_s)

      def self.uri_path
        @@asset_file.uri_path
      end
    end

    # Dummy implementation for compiler reasons
    def self.uri_path
      nil
    end

    def self.to_html_attrs(_tag, attrs)
      attrs["rel"] = "stylesheet"
      attrs["href"] = uri_path
    end

    ToHtml.class_template do
      link self
    end
  end
end
