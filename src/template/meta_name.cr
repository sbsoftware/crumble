enum MetaName
  Viewport

  def to_s(io)
    io << self.to_s.dasherize
  end

  def html_attr_key
    "name"
  end

  def html_attr_value(io)
    io << self
  end
end
