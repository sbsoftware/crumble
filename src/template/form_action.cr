class FormAction
  @path : String

  def initialize(@path); end

  def to_tag_attr
    {"action", @path}
  end
end
