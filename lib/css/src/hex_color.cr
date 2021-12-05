class HexColor
  @components : Tuple(UInt8, UInt8, UInt8)
      
  def initialize(@components); end
      
  def to_s
    "##{@components[0].to_s(16, upcase: true)}#{@components[1].to_s(16, upcase: true)}#{@components[2].to_s(16, upcase: true)}"
  end
end
