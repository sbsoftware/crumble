enum Rel
  Stylesheet
  External
  Noopener
  Nofollow
  Icon
  Alternate
  MaskIcon

  def to_s
    super.dasherize
  end

  def to_tag_attr
    {"rel", self}
  end
end
