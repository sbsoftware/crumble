require "./asset_file_registry"
require "digest/md5"

class AssetFile
  getter uri_path : String
  getter contents : String
  getter etag : String

  def initialize(uri_path, @contents)
    @etag = Digest::MD5.hexdigest(@contents)
    file, _, extension = uri_path.rpartition('.')
    @uri_path = "#{file}_#{etag}.#{extension}"
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
      ctx.response.headers["ETag"] = file.etag
      ctx.response.headers["Cache-Control"] = "public, max-age=315360000, immutable"

      if ctx.request.headers["If-None-Match"]?.try { |inm| inm.includes?(file.etag) }
        ctx.response.status_code = 304
        return true
      end

      ctx.response.print file
      return true
    end
    return false
  end

  def mime_type
    "application/octet-stream"
  end

  def to_tag_attr
    {"src", uri_path}
  end

  def to_s(io : IO)
    io << @contents
  end
end

require "./*"
