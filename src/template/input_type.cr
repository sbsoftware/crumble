enum InputType
  Text

  def to_tag_attr
    {"type", self}
  end
end
