record Percent, value : (Int32 | Float64) do
  def to_s(io : IO)
    io << value
    io << "%"
  end
end

module PercentInclude
  def percent
    Percent.new(self)
  end
end

struct Int32
  include PercentInclude
end

struct Float64
  include PercentInclude
end
