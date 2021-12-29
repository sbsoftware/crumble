class ResourcePath
  @resource_class : Resource.class
  @id : Int64?

  def initialize(@resource_class)
  end

  def initialize(@resource_class, @id)
  end

  def uri_path
    to_s
  end

  def to_s(io : IO)
    io << @resource_class.uri_path
    if @id
      io << "/"
      io << @id
    end
  end
end
