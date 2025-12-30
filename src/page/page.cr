require "../server/view_handler"

abstract class Crumble::Page
  include Crumble::Server::ViewHandler

  @path_params : Hash(Symbol, String)?

  module PathPart
  end

  struct NestedPathPart
    include PathPart

    getter segment : String

    def initialize(segment : String)
      @segment = segment.gsub(/\A\/+|\/+\z/, "")
    end
  end

  struct ParamPathPart
    include PathPart

    getter name : Symbol
    getter matcher : Regex

    def initialize(name : Symbol, matcher : Regex)
      @name = name
      @matcher = matcher
    end
  end

  PATH_PARTS = [] of PathPart

  def self._path_parts : Array(PathPart)
    PATH_PARTS
  end

  macro inherited
    PATH_PARTS = [] of Crumble::Page::PathPart

    def self._path_parts : Array(Crumble::Page::PathPart)
      PATH_PARTS
    end
  end

  macro root_path(path)
    {% unless path.is_a?(StringLiteral) %}
      {% raise "root_path expects a String literal" %}
    {% end %}
    {% unless path.starts_with?("/") %}
      {% raise "root_path must start with /" %}
    {% end %}

    def self.root_path
      {{path}}
    end
  end

  macro path_param(name, matcher = /\d+/)
    {% if name.is_a?(Call) && (name.receiver || name.args.size > 0) %}
      {% raise "path_param name must be a simple identifier (got #{name})" %}
    {% end %}

    {% unless name.id.stringify =~ /\A[a-zA-Z_][a-zA-Z0-9_]*\z/ %}
      {% raise "path_param name must be a valid method name (got #{name})" %}
    {% end %}

    PATH_PARTS << Crumble::Page::ParamPathPart.new({{name.id.symbolize}}, {{matcher}})

    def {{name.id}} : String
      path_params[{{name.id.symbolize}}]
    end
  end

  macro nested_path(path)
    {% unless path.is_a?(StringLiteral) %}
      {% raise "nested_path expects a String literal" %}
    {% end %}

    PATH_PARTS << Crumble::Page::NestedPathPart.new({{path}})
  end

  macro view(klass = nil, &blk)
    {% raise "Pass a view class or a block, not both" if klass && blk %}
    {% unless klass || blk %}{% raise "Provide a view class or block" %}{% end %}

    {% if blk %}
      class View
        include Crumble::ContextView

        {{blk.body}}
      end

      def page_view
        View.new(ctx: ctx)
      end
    {% else %}
      def page_view
        {% if klass.resolve < Crumble::ContextView %}
          {{klass}}.new(ctx: ctx)
        {% else %}
          {{klass}}
        {% end %}
      end
    {% end %}
  end

  macro layout(klass, &blk)
    {% if blk %}
      class Layout < {{klass}}
        {{blk.body}}
      end

      def page_layout
        {% if klass.resolve < Crumble::ContextView %}
          Layout.new(ctx: ctx)
        {% else %}
          Layout
        {% end %}
      end
    {% else %}
      def page_layout
        {% if klass.resolve < Crumble::ContextView %}
          {{klass}}.new(ctx: ctx)
        {% else %}
          {{klass}}
        {% end %}
      end
    {% end %}
  end

  def page_view
    raise "page_view is not implemented for #{self.class}"
  end

  def self.handle(ctx) : Bool
    return false if match(ctx.request.path).nil?
    return false unless ctx.request.method == "GET"

    instance = new(ctx)
    instance.call
    true
  end

  def self.match(path)
    uri_path_matcher.match(path)
  end

  def self.root_path
    "/" + self.name.chomp("Page").gsub("::", "/").underscore
  end

  def self.root_path(id)
    "#{root_path}/#{id}"
  end

  def self.nested_path
    segments = [] of String
    _path_parts.each do |part|
      next unless part.is_a?(NestedPathPart)
      segments << part.segment
    end
    segments.empty? ? "" : "/" + segments.join("/")
  end

  def self.uri_path(*params)
    param_values = params.map(&.to_s)
    segments = root_path.split('/').reject(&.empty?)

    param_index = 0
    _path_parts.each do |part|
      case part
      when NestedPathPart
        segments << part.segment
      when ParamPathPart
        value = param_values[param_index]? || raise ArgumentError.new("Missing path param '#{part.name}' for #{self}")
        segments << value
        param_index += 1
      end
    end

    if param_index != param_values.size
      raise ArgumentError.new("Too many path params for #{self}: expected #{param_index}, got #{param_values.size}")
    end

    "/" + segments.join("/")
  end

  def self.uri_path_matcher
    root_segments = root_path.split('/').reject(&.empty?)
    segment_patterns = root_segments.map { |seg| Regex.escape(seg) }

    _path_parts.each do |part|
      case part
      when NestedPathPart
        segment_patterns << Regex.escape(part.segment)
      when ParamPathPart
        segment_patterns << "(#{part.matcher.source})"
      end
    end

    if segment_patterns.empty?
      /^\/$/
    else
      Regex.new("^/" + segment_patterns.join("/") + "/?$")
    end
  end

  def initialize(@request_ctx); end

  def page_layout
    nil
  end

  def call
    tpl = page_view
    ctx.response.headers["Content-Type"] = "text/html"

    if layout = page_layout
      layout.to_html(ctx.response) do |io, indent_level|
        if tpl.responds_to?(:to_html)
          tpl.to_html(io, indent_level)
        else
          tpl.to_s(io)
        end
      end
    else
      if tpl.responds_to?(:to_html)
        tpl.to_html(ctx.response)
      else
        tpl.to_s(ctx.response)
      end
    end
  end

  def id?
    path_params[:id]?.try(&.to_i64?)
  end

  def id
    id?.not_nil!
  end

  def nested?
    self.class._path_parts.size > 0
  end

  def top_level?
    !nested?
  end

  def self.to_html_attrs(_tag, attrs)
    attrs["href"] = uri_path
  end

  def window_title : String?
    nil
  end

  protected def path_params : Hash(Symbol, String)
    @path_params ||= begin
      params = {} of Symbol => String
      match = self.class.match(ctx.request.path)
      return params unless match

      capture_index = 1
      self.class._path_parts.each do |part|
        if part.is_a?(ParamPathPart)
          params[part.name] = match[capture_index]
          capture_index += 1
        end
      end
      params
    end
  end
end
