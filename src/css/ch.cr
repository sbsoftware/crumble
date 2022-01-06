record Ch, value : (Int32 | Float64) do
  def to_s(io : IO)
    io << value
    io << "ch"
  end
end

struct Float64
  def ch
    Ch.new(self)
  end
end

struct Int32
  def ch
    Ch.new(self)
  end
end
