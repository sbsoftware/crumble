require "../server/handler"

module AssetFileRegistry
  include Crumble::Server::Handler

  extend self

  @@asset_files = {} of String => AssetFile

  def handle(ctx) : Bool
    if file = query(ctx.request.path)
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

  def add(path, asset_file)
    @@asset_files[path] = asset_file
  end

  def query(path)
    @@asset_files[path]?
  end
end
