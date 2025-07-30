require "../server/view_handler"

abstract class Crumble::Resource
  include Crumble::Server::ViewHandler

  macro before(&blk)
    before(:index, :create, :show, :update, :destroy) {{blk}}
  end

  macro before(*actions, &blk)
    {% for action in actions %}
      def _before_{{action.id}}
        {% if @type.has_method?("_before_#{action.id}") %}
          {% if @type.methods.map(&.name).includes?("_before_#{action.id}") %}
            prev = previous_def
          {% else %}
            prev = super
          {% end %}
          return prev unless prev == true
        {% end %}

        {{blk.body}}
      end
    {% end %}
  end

  macro before_action_handling(instance, action_name)
    if {{instance}}.responds_to? :_before_{{action_name.id}}
      %ret_val = {{instance}}._before_{{action_name.id}}
      if %ret_val == false
        ctx.response.status = :bad_request
        return true
      elsif %ret_val.is_a?(Int32)
        ctx.response.status_code = %ret_val
        return true
      end
    end
  end

  def self.handle(ctx) : Bool
    return false if match(ctx.request.path).nil?

    instance = self.new(ctx)

    case ctx.request.method
    when "GET"
      if instance.id? && instance.top_level?
        before_action_handling(instance, :show)
        instance.show
      else
        before_action_handling(instance, :index)
        instance.index
      end
    when "POST"
      if instance.id? && instance.top_level?
        before_action_handling(instance, :update)
        instance.update
      else
        before_action_handling(instance, :create)
        instance.create
      end
    when "DELETE"
      before_action_handling(instance, :destroy)
      instance.destroy
    end
    return true
  end

  def self.match(path)
    uri_path_matcher.match(path)
  end

  def self.root_path
    "/" + self.name.chomp("Resource").gsub("::", "/").underscore
  end

  def self.root_path(id : Nil)
    ""
  end

  def self.root_path(id)
    "#{root_path}/#{id}"
  end

  def self.nested_path
    ""
  end

  def self.uri_path
    root_path
  end

  def self.uri_path(id : Nil)
    ""
  end

  def self.uri_path(id)
    "#{root_path(id)}#{nested_path}"
  end

  def self.uri_path_matcher
    /^#{root_path}(\/|\/(\d+)(#{nested_path})?)?$/
  end

  def initialize(@request_ctx); end

  def resource_layout
    nil
  end

  macro layout(klass, &blk)
    {% if blk %}
      class Layout < {{klass}}
        {{blk.body}}
      end

      def resource_layout
        {% if klass.resolve < Crumble::ContextView %}
          Layout.new(ctx: ctx)
        {% else %}
          Layout
        {% end %}
      end
    {% else %}
      def resource_layout
        {% if klass.resolve < Crumble::ContextView %}
          {{klass}}.new(ctx: ctx)
        {% else %}
          {{klass}}
        {% end %}
      end
    {% end %}
  end

  macro render(tpl)
    {% if tpl.is_a?(Path) && tpl.resolve < Crumble::ContextView %}
      %tpl = {{tpl}}.new(ctx: ctx)
    {% else %}
      %tpl = {{tpl}}
    {% end %}

    ctx.response.headers["Content-Type"] = "text/html"

    if %layout = resource_layout
      %layout.to_html(ctx.response) do |io, indent_level|
        %tpl.to_html(io, indent_level)
      end
    else
      if %tpl.responds_to?(:to_html)
        %tpl.to_html(ctx.response)
      else
        %tpl.to_s(ctx.response)
      end
    end
  end

  def redirect(new_path)
    ctx.response.status_code = 303
    ctx.response.headers["Location"] = new_path
  end

  def redirect_back(fallback_path)
    redirect(ctx.request.headers["Referer"]? || fallback_path)
  end

  def index
    ctx.response.status_code = 404
    ctx.response.print "Not Found"
  end

  def show
    ctx.response.status_code = 404
    ctx.response.print "Not Found"
  end

  def create
    ctx.response.status_code = 404
    ctx.response.print "Not Found"
  end

  def update
    ctx.response.status_code = 404
    ctx.response.print "Not Found"
  end

  def destroy
    ctx.response.status_code = 404
    ctx.response.print "Not Found"
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
    # TODO: Use some default app name, maybe to be defined in Crumble::Server?
    nil
  end
end
