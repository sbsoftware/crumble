enum Charset
  UTF8

  def to_s
    case self
    in UTF8 then "utf-8"
    end
  end

  def to_tag_attr
    {"charset", self}
  end
end
