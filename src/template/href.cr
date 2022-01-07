class Href
  @value : String

  def initialize(@value)
  end

  def html_attr_key
    "href"
  end

  def html_attr_value(io)
    io << @value
  end
end
