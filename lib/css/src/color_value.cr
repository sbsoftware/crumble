require "./named_color"
require "./hex_color"

module CSS
  module ColorValue
    getter value : CSS::NamedColor | HexColor

    def initialize(value : Tuple(UInt8, UInt8, UInt8))
      @value = HexColor.new(value)
    end

    def initialize(@value : CSS::NamedColor); end
  end
end
