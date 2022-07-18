enum MetaName
  Viewport
  Description

  def to_s
    super.dasherize
  end

  def to_tag_attr
    {"name", self}
  end
end
