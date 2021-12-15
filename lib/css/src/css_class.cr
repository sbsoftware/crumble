require "./class_property"
require "./background_color"
require "./color"
require "./named_color"

class String
  def dasherize
    underscore.gsub("_", "-")
  end
end

module CSS
  abstract class CSSClass
    @@properties = [] of CSS::ClassProperty

    macro backgroundColor(c)
      {% if c.is_a?(Path) %}
        _backgroundColor CSS::NamedColor::{{c}}
      {% elsif c.is_a?(TupleLiteral) %}
        _backgroundColor({{c}})
      {% end %}
    end
    
    macro color(c)
      _color CSS::NamedColor::{{c}}
    end
    
    def self._backgroundColor(c)
      @@properties << CSS::BackgroundColor.new(c)
    end

    def self._color(c)
      @@properties << CSS::Color.new(c)
    end

    def self.to_inline_css
      @@properties.join "; "
    end

    def self.to_css
      String.build do |str|
        str << "."
        str << self
        str << "{\n"
        @@properties.each do |prop|
          str << prop
          str << ";\n"
        end
        str << "}\n"
      end
    end

    def self.to_s(io : IO)
      io << self.name.dasherize
    end
  end
end
