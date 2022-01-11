class HexColor
  @components : Tuple(UInt8, UInt8, UInt8)
      
  def initialize(components)
    @components = components.map(&.to_u8)
  end
      
  def to_s(io : IO)
    io << "#"
    @components.each do |comp|
      io << comp.to_s(16, upcase: true).rjust(2, '0')
    end
  end
end
