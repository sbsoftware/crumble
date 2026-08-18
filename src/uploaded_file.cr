require "http/headers"

module Crumble
  # A request-scoped multipart upload stored in framework-managed temporary storage.
  #
  # `filename` is only the normalized client-provided basename and must never be
  # treated as a safe server path. `content_type` is also client-provided and
  # untrusted. Crumble removes `path` at the end of the request, including when
  # the action raises. Read, copy, process, or move the file during the request
  # if it must outlive that request. Moving is supported; cleanup tolerates the
  # original path no longer existing.
  class UploadedFile
    @headers : HTTP::Headers
    getter filename : String
    getter content_type : String?
    getter size : Int64
    getter path : String

    def initialize(filename, @content_type, headers, @size, @path)
      # Browsers should send a basename, but some clients still expose either
      # path separator. Never allow that metadata to become a server path.
      @filename = filename.gsub('\\', '/').split('/').last? || ""
      @headers = headers.dup
    end

    # Returns a copy so callers cannot mutate the upload's captured metadata.
    def headers : HTTP::Headers
      @headers.dup
    end

    # Opens the managed temporary file for safe, scoped reading.
    def open(& : IO -> T) : T forall T
      File.open(path, "r") { |io| yield io }
    end
  end
end
