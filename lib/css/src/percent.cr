record Percent, value : Int32 do
  def to_s(io : IO)
    io << value
    io << "%"
  end
end

struct Int32
  def percent
    Percent.new(self)
  end
end
