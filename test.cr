module BuildContext
  macro capture_elems(io, &blk)
    {% if blk %}
      {% if blk.body.is_a?(Expressions) %}
        {% for exp in blk.body.expressions %}
          {% if exp.is_a?(Call) %}
            {% if exp.block %}
              {{exp.name}}({{exp.args.unshift(io.id).splat}}) do
                BuildContext.capture_elems(io) {{exp.block}}
              end
            {% else %}
              {{exp.name}}({{exp.args.unshift(io).splat}})
            {% end %}
          {% end %}
        {% end %}
      {% else %}
        {% if blk.body.is_a?(Call) %}
          {% if blk.body.block %}
            {{blk.body.name}}({{blk.body.args.unshift(io).splat}}) do
              BuildContext.capture_elems(io) {{blk.body.block}}
            end
          {% else %}
            {{blk.body.name}}({{blk.body.args.unshift(io).splat}})
          {% end %}
        {% end %}
      {% end %}
    {% end %}
    {{debug}}
  end
end

class View(T)
  @model : T

  def initialize(@model)
  end

  macro template(&blk)
    def render
      String.build do |io|
        BuildContext.capture_elems(io) {{blk}}
      end
    end
    {{debug}}
  end

  macro div(io, css_class = nil, &block)
    tag({{io.id}}, "div", false, {{css_class}}) {{block}}
  end

  @[AlwaysInline]
  def tag(io : String::Builder, name : String, standalone : Bool, css_class : String? = nil)
    io << "<"
    io << name
    if css_class
      io << " class=\""
      io << css_class
      io << "\""
    end
    if standalone
      io << "/>"
      return
    end
    io << ">"
    yield(io)
    io << "</"
    io << name
    io << ">"
  end

  def tag(io : String::Builder, name : String, standalone : Bool, css_class : String? = nil)
    io << "<"
    io << name
    if css_class
      io << " class=\""
      io << css_class
      io << "\""
    end
    if standalone
      io << "/>"
      return
    end
    io << ">"
    io << "</"
    io << name
    io << ">"
  end
end

class Elmnt
  @tag_name : String = "div"
  @css_class : String?
  @elems : Array(Elmnt | String | -> String)

  def initialize(@css_class = nil, @elems = [] of Elmnt | String | -> String)
  end

  def render(_m) : String
    "<#{@tag_name} class=\"#{@css_class}\">#{render_elems(_m)}</#{@tag_name}>"
  end

  def render_elems(_m)
    rendered = @elems.map do |elem|
      if elem.responds_to? :render
        elem.render(_m)
      else
        elem.to_s
      end
    end.join("\n  ")

    if rendered.size > 0
      "\n  #{rendered}\n"
    else
      ""
    end
  end
end

class MyData
  @theprop : String

  def initialize(@theprop = "Penis")
  end
end

class MyView(T) < View(T)
  template do
    div do
      div "bla" do
        div
      end
      div "blu" do
        div "mama"
      end
    end
    div do
      div "gu"
      div "ga"
    end
  end
end

puts MyView(MyData).new(MyData.new).render
