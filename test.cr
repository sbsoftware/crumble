module BuildContext
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
  end

  macro eval_exp(&blk)
    {% if blk.body.is_a?(Call) %}
      {% if Template::TAG_NAMES.includes?(blk.body.name.stringify) %}
        {% if blk.body.block %}
          {% if blk.body.named_args && blk.args.size > 0 %}
            {{blk.body.name}}({{blk.body.args.splat}}, {{blk.body.named_args.splat}}) do
          {% elsif blk.body.named_args && blk.args.empty? %}
            {{blk.body.name}}({{blk.body.named_args.splat}}) do
          {% else %}
            {{blk.body.name}}({{blk.body.args.splat}}) do
          {% end %}
            BuildContext.capture_elems {{blk.body.block}}
          end
        {% else %}
          {{blk.body}}
        {% end %}
      {% else %}
        __tplio__ << {{blk.body}}
      {% end %}
    {% elsif blk.body.is_a?(StringLiteral) %}
      __tplio__ << {{blk.body + "\n"}}
    {% else %}
      {{pp blk.body}}
    {% end %}
  end
end

class Template
  TAG_NAMES = %w(html head title body div strong form)

  # default implementation to calm down the compiler
  def to_s(__tplio__ : IO)
  end

  macro template(&blk)
    def to_s(__tplio__ : IO)
      BuildContext.capture_elems {{blk}}
    end
  end

  {% for tag_name in TAG_NAMES %}
    macro {{tag_name.id}}(css_class = nil, attrs = {} of String => String, &block)
      tag(__tplio__, {{tag_name}}, \{{css_class}}, \{{attrs}}) \{{block}}
    end
  {% end %}

  def tag(io, name, css_class, attrs)
    start_tag(io, name, css_class, attrs)
    io << "\n"
    yield(io)
    end_tag(io, name)
  end

  def tag(io, name, css_class, attrs)
    start_tag(io, name, css_class, attrs)
    end_tag(io, name)
  end

  @[AlwaysInline]
  def start_tag(io : IO, name : String, css_class : String?, attrs : Hash(String, String))
    io << "<"
    io << name
    if css_class
      io << " class=\""
      io << css_class
      io << "\""
    end
    attrs.each do |(k, v)|
      io << " "
      io << k
      io << "=\""
      io << v
      io << "\""
    end
    io << ">"
  end

  @[AlwaysInline]
  def end_tag(io : IO, name : String)
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

  def default_view
    MyView(self).new(self)
  end
end

record MyOtherData, theprop : String, theklass : String

class MyView(T) < View(T)
  template do
    div do
      div "bla" do
        div theklass, {"data-controller" => "Something"} do
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
    div attrs: {"lang" => "EN"} do
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
        site_body
      end
    end
  end
end

record SiteStructure, site_title : String, site_body : Template

puts MyData.new("PIMMEL").default_view
puts "#####"
puts MyView(MyOtherData).new(MyOtherData.new("Suburu", "geneter"))
puts "#####"
puts MyLayout(SiteStructure).new(SiteStructure.new("3 TAGE WACH", MyView(MyData).new(MyData.new("IMPORANT DATA"))))
