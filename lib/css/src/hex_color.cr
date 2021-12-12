class HexColor
  @components : Tuple(UInt8, UInt8, UInt8)
      
  def initialize(@components); end
      
  def to_s(io : IO)
    io << "#"
    @components.each do |comp|
      io << comp.to_s(16, upcase: true)
    end
  end
end
