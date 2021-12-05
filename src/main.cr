require "css"

class MyClass < CSS::CSSClass
  backgroundColor Silver
  color Black
end

class MyOtherClass < CSS::CSSClass
  backgroundColor({0xFFu8, 0xFFu8, 0xFFu8})
  color White
end

enum Tag
  Div

  def to_s
    case self
    in Div then "div"
    end
  end
end

class MyData
  @prop1 : String?
  @prop2 : Int32?
end

class HTMLElement
  @tag_name : Tag
  @content : Array(HTMLElement | String)
  @css_class : CSS::CSSClass.class | Nil

  def initialize(@tag_name = Tag::Div, @css_class = nil)
    @content = [] of Array(HTMLElement | String)
  end

  def to_s
    "<#{@tag_name.to_s} style=\"#{@css_class.try &.to_inline_css}\">#{@content.map(&:to_s).join}</#{@tag_name.to_s}>"
  end
end

abstract class HTMLView
  def initialize
    @elements = [] of HTMLElement
    elements
  end

  abstract def elements
  
  def div(css_class)
    @elements << HTMLElement.new(Tag::Div, css_class)
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
      div(MyClass) do
        "Penis"
      end
    end
  end
end

puts MyHTMLView.new.to_s
