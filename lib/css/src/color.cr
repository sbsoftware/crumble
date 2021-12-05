require "./class_property"
require "./color_value"

module CSS
  class Color < CSS::ClassProperty
    include CSS::ColorValue
    
    def name
      "color"
    end
  end
end
