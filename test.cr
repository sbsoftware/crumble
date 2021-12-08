module BuildContext
  TAG_METHODS = ["html", "head", "title", "body", "div", "strong"]

  macro capture_elems(&blk)
    {% if blk %}
      {% if blk.body.is_a?(Expressions) %}
        {% for exp in blk.body.expressions %}
          BuildContext.eval_exp do
            {{exp}}
          end
        {% end %}
      {% else %}
        BuildContext.eval_exp {{blk}}
      {% end %}
    {% end %}
    {{debug}}
  end

  macro eval_exp(&blk)
    {% if blk.body.is_a?(Call) %}
      {% if TAG_METHODS.includes?(blk.body.name.stringify) %}
        {% if blk.body.block %}
          {{blk.body.name}}({{blk.body.args.splat}}) do
            BuildContext.capture_elems {{blk.body.block}}
          end
        {% else %}
          {{blk.body.name}}({{blk.body.args.splat}})
        {% end %}
      {% else %}
        {% if blk.body.receiver %}
          __tplio__ << {{blk.body.receiver}}.{{blk.body.name}}({{blk.body.args.splat}}) {{blk.body.block}}
        {% else %}
          __tplio__ << {{blk.body.name}}({{blk.body.args.splat}}) {{blk.body.block}}
        {% end %}
      {% end %}
    {% elsif blk.body.is_a?(StringLiteral) %}
      __tplio__ << {{blk.body + "\n"}}
    {% else %}
      {{pp blk.body}}
    {% end %}
  end
end

class Template
  # default implementation to calm down the compiler
  def render
    ""
  end

  macro template(&blk)
    def render
      String.build do |__tplio__|
        BuildContext.capture_elems {{blk}}
      end
    end
  end

  macro html(&block)
    tag(__tplio__, "html", false, nil) {{block}}
  end

  macro head(&block)
    tag(__tplio__, "head", false, nil) {{block}}
  end

  macro title(&block)
    tag(__tplio__, "title", false, nil) {{block}}
  end

  macro body(css_class = nil, &block)
    tag(__tplio__, "body", false, {{css_class}}) {{block}}
  end

  macro div(css_class = nil, &block)
    tag(__tplio__, "div", false, {{css_class}}) {{block}}
  end

  macro strong(css_class = nil, &block)
    tag(__tplio__, "strong", false, {{css_class}}) {{block}}
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
      io << "/>\n"
      return
    end
    io << ">\n"
    yield(io)
    io << "</"
    io << name
    io << ">\n"
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
      io << "/>\n"
      return
    end
    io << ">"
    io << "</"
    io << name
    io << ">\n"
  end
end

class View(T) < Template
  @model : T

  forward_missing_to @model

  def initialize(@model)
  end
end

class MyData
  getter theprop : String

  def initialize(@theprop = "Penis")
  end

  def theklass
    "special"
  end
end

record MyOtherData, theprop : String, theklass : String

class MyView(T) < View(T)
  template do
    div do
      div "bla" do
        div theklass do
          "This is:"
          strong { theprop }
        end
      end
      div "blu" do
        div "mama" do
          "Inhalt"
        end
      end
    end
    div do
      div "gu"
      div "ga" do
        "Penis"
        "Vagina"
      end
    end
  end
end

class MyLayout(T) < View(T)
  template do
    html do
      head do
        title do
          site_title
        end
      end
      body do
        site_body.render
      end
    end
  end
end

record SiteStructure, site_title : String, site_body : Template

puts MyView(MyData).new(MyData.new("PIMMEL")).render
puts "#####"
puts MyView(MyOtherData).new(MyOtherData.new("Suburu", "geneter")).render
puts "#####"
puts MyLayout(SiteStructure).new(SiteStructure.new("3 TAGE WACH", MyView(MyData).new(MyData.new("IMPORANT DATA")))).render
