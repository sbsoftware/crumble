record Pixels, value : Int32 do
  def to_s(io : IO)
    io << value
    io << "px"
  end
end

struct Int32
  def px
    Pixels.new(self)
  end
end
