enum Charset
  UTF8

  def to_s(io)
    io << case self
          in UTF8 then "utf-8"
          end
  end

  def html_attr_key
    "charset"
  end

  def html_attr_value(io)
    io << self
  end
end
