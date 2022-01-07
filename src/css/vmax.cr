record Vmax, value : (Int32 | Float64) do
  def to_s(io : IO)
    io << value
    io << "vmax"
  end
end

module VmaxInclude
  def vmax
    Vmax.new(self)
  end
end

struct Float64
  include VmaxInclude
end

struct Int32
  include VmaxInclude
end
