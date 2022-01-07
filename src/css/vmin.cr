record Vmin, value : (Int32 | Float64) do
  def to_s(io : IO)
    io << value
    io << "vmin"
  end
end

module VminInclude
  def vmin
    Vmin.new(self)
  end
end

struct Float64
  include VminInclude
end

struct Int32
  include VminInclude
end
