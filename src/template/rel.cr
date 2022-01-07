enum Rel
  Stylesheet
  External
  Noopener
  Nofollow

  def to_s(io)
    io << self.to_s.dasherize
  end

  def html_attr_key
    "rel"
  end

  def html_attr_value(io)
    io << self
  end
end
