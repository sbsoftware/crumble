enum InputType
  Text

  def to_s(io)
    io << self.to_s
  end

  def html_attr_key
    "type"
  end

  def html_attr_value(io)
    io << self
  end
end
