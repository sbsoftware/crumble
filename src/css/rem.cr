record Rem, value : (Int32 | Float64) do
  def to_s(io : IO)
    io << value
    io << "rem"
  end
end

struct Float64
  def rem
    Rem.new(self)
  end
end

struct Int32
  def rem
    Rem.new(self)
  end
end
