record Vw, value : (Int32 | Float64) do
  def to_s(io : IO)
    io << value
    io << "vw"
  end
end

struct Float64
  def vw
    Vw.new(self)
  end
end

struct Int32
  def vw
    Vw.new(self)
  end
end
