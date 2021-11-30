enum CSSNamedColor
  Black
  Silver
  White
  
  def to_s
    case self
    in Black then "black"
    in Silver then "silver"
    in White then "white"
    end
  end
end
    
class HexColor
  @components : Tuple(UInt8, UInt8, UInt8)
      
  def initialize(@components); end
      
  def to_s
    "##{@components[0].to_s(16, upcase: true)}#{@components[1].to_s(16, upcase: true)}#{@components[2].to_s(16, upcase: true)}"
  end
end
  
abstract class CSSClassProperty
  abstract def name  
  abstract def value
  
  def to_s
    "#{name}: #{value.to_s}"
  end
end

class BackgroundColor < CSSClassProperty
  getter value : CSSNamedColor | HexColor | String
  
  def initialize(value : Tuple(UInt8, UInt8, UInt8))
    @value = HexColor.new(value)
  end
    
  def initialize(@value : (CSSNamedColor | String)); end
  
  def name
    "background-color"
  end
end

class Color < CSSClassProperty
  getter value : CSSNamedColor | HexColor | String
  
  def initialize(@value); end
  
  def name
    "color"
  end
end

abstract class CSSClass
  @@properties = [] of CSSClassProperty

  macro backgroundColor(c)
    {% if c.is_a?(Path) %}
      _backgroundColor CSSNamedColor::{{c}}
    {% elsif c.is_a?(TupleLiteral) %}
      _backgroundColor({{c}})
    {% end %}
  end
  
  macro color(c)
    _color CSSNamedColor::{{c}}
  end
  
  def self._backgroundColor(c)
    @@properties << BackgroundColor.new(c)
  end

  def self._color(c)
    @@properties << Color.new(c)
  end

  def self.to_inline_css
    @@properties.join "; ", &.to_s
  end
end

class MyClass < CSSClass
  backgroundColor Silver
  color Black
end

class MyOtherClass < CSSClass
  backgroundColor({0xFFu8, 0xFFu8, 0xFFu8})
  color White
end

abstract class HTMLElement
  @text_content : String?
  @css_class : CSSClass.class | Nil

  def initialize(@text_content, @css_class)
  end

  abstract def tag
  
  def to_s
    "<#{tag} style=\"#{@css_class.try &.to_inline_css}\">#{@text_content}</#{tag}>"
  end
end

class DivElement < HTMLElement
  def tag
    "div"
  end
end

abstract class HTMLView
  def initialize
    @elements = [] of HTMLElement
    elements
  end

  abstract def elements
  
  def div(css_class)
    @elements << DivElement.new(yield, css_class)
  end
  
  def to_s
    @elements.map(&.to_s).join("\n")
  end
end

class MyHTMLView < HTMLView
  def elements
    div(MyClass) do
      "Test"
    end
    div(MyOtherClass) do
      "Penis"
    end
  end
end

puts MyHTMLView.new.to_s
