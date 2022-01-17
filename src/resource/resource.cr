require "./resource_path"

class Resource
  @ctx : HTTP::Server::Context

  def self.handle(ctx)
    return false if match(ctx.request.path).nil?

    instance = self.new(ctx)

    case ctx.request.method
    when "GET"
      instance.index
    end
    return true
  end

  def self.match(path)
    uri_path_matcher.match(path)
  end

  def self.uri_path
    "/" + self.name.chomp("Resource").gsub("::", "/").underscore
  end

  def self.uri_path(id)
    "#{uri_path}/#{id}"
  end

  def self.uri_path_matcher
    /#{uri_path}(\/|\/(\d+))?$/
  end

  def initialize(@ctx)
  end

  def render(tpl)
    @ctx.response.print tpl
  end

  def index
    @ctx.response.status_code = 404
    @ctx.response.print "Not Found"
  end

  def id
    self.class.match(@ctx.request.path).try { |m| m[2].to_i64 }.not_nil!
  end

  def self.html_attr_key
    "href"
  end

  def self.html_attr_value(io)
    io << uri_path
  end
end
