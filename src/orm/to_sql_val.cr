class String
  def to_sql_val(io : IO)
    io << "'"
    io << self
    io << "'"
  end
end

struct Int32
  def to_sql_val(io : IO)
    io << self
  end
end

struct Int64
  def to_sql_val(io : IO)
    io << self
  end
end
