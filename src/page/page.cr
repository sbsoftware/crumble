require "../server/view_handler"

abstract class Crumble::Page
  include Crumble::Server::ViewHandler

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
    ""
  end

  def self.uri_path(id = nil)
    path = root_path
    if id
      path += "/#{id}"
      path += nested_path
    end
    path
  end

  def self.uri_path_matcher
    if nested_path.empty?
      /^#{root_path}(\/|\/(\d+))?$/
    else
      /^#{root_path}(\/|\/(\d+)(#{nested_path})?)?$/
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
    self.class.match(ctx.request.path).try { |m| m[2]?.try(&.to_i64) }
  end

  def id
    id?.not_nil!
  end

  def nested?
    self.class.nested_path.size > 0
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
end
