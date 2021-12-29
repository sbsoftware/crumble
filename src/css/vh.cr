record Vh, value : (Int32 | Float64) do
  def to_s(io : IO)
    io << value
    io << "vh"
  end
end

struct Float64
  def vh
    Vh.new(self)
  end
end

struct Int32
  def vh
    Vh.new(self)
  end
end
