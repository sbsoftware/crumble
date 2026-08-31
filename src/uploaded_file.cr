require "http"

module Crumble
  # Metadata and request-scoped storage for a successfully accepted upload.
  #
  # `filename` is reduced to a basename and must never be treated as a safe or
  # unique server path. `content_type` and all headers are supplied by the
  # client and are untrusted. Crumble deletes `path` after request dispatch,
  # including exceptional exits. Read or copy the file during that lifetime;
  # moving it is unsupported because Crumble retains ownership of the path.
  class UploadedFile
    @headers : HTTP::Headers

    getter filename : String
    getter content_type : String?
    getter size : Int64
    getter path : String

    def initialize(filename : String, @content_type : String?, headers : HTTP::Headers, @size : Int64, @path : String)
      @filename = filename.split(/[\\\/]/).last? || ""
      @headers = headers.dup
    end

    # Returns a copy so callers cannot mutate the upload's captured metadata.
    def headers : HTTP::Headers
      @headers.dup
    end

    # Opens the framework-managed temporary file for safe, scoped reading.
    def open(& : IO -> U) : U forall U
      File.open(path) { |io| yield io }
    end

    def self.from_multipart(files : Array(UploadedFile)?) : UploadedFile?
      files.try(&.first?)
    end

    # URL-encoded requests cannot carry file contents.
    def self.from_www_form(value : String) : UploadedFile?
      nil
    end
  end
end

def Array.from_multipart(files : Array(Crumble::UploadedFile)?)
  return unless files
  files.map(&.as(T))
end

def Union.from_multipart(files : Array(Crumble::UploadedFile)?)
  {% for type in T %}
    {% unless type == Nil %}
      return {{type}}.from_multipart(files)
    {% end %}
  {% end %}
  nil
end
