record Em, value : (Int32 | Float64) do
  def to_s(io : IO)
    io << value
    io << "em"
  end
end

struct Float64
  def em
    Em.new(self)
  end
end

struct Int32
  def em
    Em.new(self)
  end
end
