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

  def mime_type
    "application/octet-stream"
  end

  def to_html_attrs(_tag, attrs)
    attrs["src"] = uri_path
  end

  def to_s(io : IO)
    io << @contents
  end

  def to_js_ref
    uri_path
  end
end

require "./*"
