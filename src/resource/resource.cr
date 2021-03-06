require "./resource_path"

abstract class Resource
  @ctx : HTTP::Server::Context
  getter layout : Template?

  def self.handle(ctx)
    return false if match(ctx.request.path).nil?

    instance = self.new(ctx)

    case ctx.request.method
    when "GET"
      instance.index
    when "POST"
      if instance.id? && instance.top_level?
        if instance.responds_to? :update
          instance.update
        else
          return false
        end
      else
        if instance.responds_to? :create
          instance.create
        else
          return false
        end
      end
    when "DELETE"
      if instance.responds_to? :destroy
        instance.destroy
      else
        return false
      end
    end
    return true
  end

  def self.match(path)
    uri_path_matcher.match(path)
  end

  def self.root_path
    "/" + self.name.chomp("Resource").gsub("::", "/").underscore
  end

  def self.root_path(id : Crumble::ORM::Attribute)
    root_path(id.value)
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

  def self.uri_path(id : Crumble::ORM::Attribute)
    uri_path(id.value)
  end

  def self.uri_path(id : Nil)
    ""
  end

  def self.uri_path(id)
    "#{root_path(id)}#{nested_path}"
  end

  def self.uri_path_matcher
    /#{root_path}(\/|\/(\d+)(#{nested_path})?)?$/
  end

  def initialize(@ctx)
    layout_cls = layout_class
    if layout_cls.is_a?(Template.class)
      @layout = layout_cls.new.tap do |layout|
        layout_config(layout)
      end
    end
  end

  def layout_class
    nil
  end

  def layout_config(layout)
  end

  def render(tpl)
    layout = @layout
    if layout.is_a?(Template)
      layout.main_docking_point = tpl
      @ctx.response.print layout
    else
      @ctx.response.print tpl
    end
  end

  def index
    @ctx.response.status_code = 404
    @ctx.response.print "Not Found"
  end

  def id?
    self.class.match(@ctx.request.path).try { |m| m[2].to_i64 }
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

  def self.html_attr_key
    "href"
  end

  def self.html_attr_value(io)
    io << uri_path
  end
end
