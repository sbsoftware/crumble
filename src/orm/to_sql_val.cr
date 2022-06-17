module ToSql
  def to_sql_where_condition(io : IO)
    sql_eq_operator(io)
    to_sql_value(io)
  end

  def to_sql_update_value(io : IO)
    io << "="
    to_sql_value(io)
  end

  def to_sql_insert_value(io : IO)
    to_sql_value(io)
  end

  abstract def to_sql_value(io : IO)

  def sql_eq_operator(io : IO)
    io << "="
  end
end

class String
  include ToSql

  def to_sql_value(io : IO)
    io << "'"
    io << self
    io << "'"
  end
end

struct Int32
  include ToSql

  def to_sql_value(io : IO)
    io << self
  end
end

struct Int64
  include ToSql

  def to_sql_value(io : IO)
    io << self
  end
end

struct Bool
  include ToSql

  def to_sql_value(io : IO)
    if self
      io << "TRUE"
    else
      io << "FALSE"
    end
  end
end

struct Time
  include ToSql

  def to_sql_value(io : IO)
    io << "'"
    io << self
    io << "'"
  end
end

struct Nil
  include ToSql

  def to_sql_value(io : IO)
    io << "NULL"
  end

  def sql_eq_operator(io : IO)
    io << " IS "
  end
end
