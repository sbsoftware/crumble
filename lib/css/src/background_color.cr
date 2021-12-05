require "./class_property"
require "./color_value"

module CSS
  class BackgroundColor < CSS::ClassProperty
    include CSS::ColorValue
    
    def name
      "background-color"
    end
  end
end
