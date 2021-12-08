module BuildContext
  TAG_METHODS = ["div", "strong"]

  macro capture_elems(&blk)
    {% if blk %}
      {% if blk.body.is_a?(Expressions) %}
        {% for exp in blk.body.expressions %}
          {% if exp.is_a?(Call) %}
            {% if TAG_METHODS.includes?(exp.name.stringify) %}
              {% if exp.block %}
                {{exp.name}}({{exp.args.splat}}) do
                  BuildContext.capture_elems {{exp.block}}
                end
              {% else %}
                {{exp.name}}({{exp.args.splat}})
              {% end %}
            {% else %}
              __tplio__ << {{exp.name}}({{exp.args.splat}}) {{exp.block}}
            {% end %}
          {% elsif exp.is_a?(StringLiteral) %}
            __tplio__ << {{exp + "\n"}}
          {% end %}
        {% end %}
      {% else %}
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
            __tplio__ << {{blk.body.name}}({{blk.body.args.splat}}) {{blk.body.block}}
          {% end %}
        {% elsif blk.body.is_a?(StringLiteral) %}
          __tplio__ << {{blk.body + "\n"}}
        {% end %}
      {% end %}
    {% end %}
  end
end

class View(T)
  @model : T

  forward_missing_to @model

  def initialize(@model)
  end

  macro template(&blk)
    def render
      String.build do |__tplio__|
        BuildContext.capture_elems {{blk}}
      end
    end
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

puts MyView(MyData).new(MyData.new("PIMMEL")).render
puts "#####"
puts MyView(MyOtherData).new(MyOtherData.new("Suburu", "geneter")).render
