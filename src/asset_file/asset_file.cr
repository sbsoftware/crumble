require "./asset_file_registry"

class AssetFile
  getter uri_path : String

  @contents : String

  def initialize(@uri_path, @contents)
    AssetFileRegistry.add(@uri_path, self)
  end

  macro register(path)
    {{@type}}.new("/{{path.id}}", {{read_file(path)}})
  end

  macro register(uri_path, source_path)
    {{@type}}.new("/{{uri_path.id}}", {{read_file(source_path)}})
  end

  def self.handle(ctx)
    if file = AssetFileRegistry.query(ctx.request.path)
      ctx.response.content_type = file.mime_type
      ctx.response.print file
      return true
    end
    return false
  end

  def mime_type
    "application/octet-stream"
  end

  def to_s(io : IO)
    io << @contents
  end
end

require "./*"
