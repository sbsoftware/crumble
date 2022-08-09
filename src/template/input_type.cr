enum InputType
  Text
  Submit
  Hidden

  def to_tag_attr
    {"type", self}
  end
end
