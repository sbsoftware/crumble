require "css"

class Template
  CONTENT_TAG_NAMES = %w(html head title body nav ul li a div strong form)
  STANDALONE_TAG_NAMES = %w(link)

  macro capture_elems(&blk)
    {% if blk %}
      {% if blk.body.is_a?(Expressions) %}
        {% for exp in blk.body.expressions %}
          eval_exp do
            {{exp}}
          end
        {% end %}
      {% else %}
        eval_exp {{blk}}
      {% end %}
    {% end %}
  end

  macro eval_exp(&blk)
    {% if blk.body.is_a?(Call) %}
      {% if (CONTENT_TAG_NAMES + STANDALONE_TAG_NAMES).includes?(blk.body.name.stringify) %}
        {% if blk.body.block %}
          {% if blk.body.named_args && blk.args.size > 0 %}
            {{blk.body.name}}({{blk.body.args.splat}}, {{blk.body.named_args.splat}}) do
          {% elsif blk.body.named_args && blk.args.empty? %}
            {{blk.body.name}}({{blk.body.named_args.splat}}) do
          {% else %}
            {{blk.body.name}}({{blk.body.args.splat}}) do
          {% end %}
            capture_elems {{blk.body.block}}
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

  # default implementation to calm down the compiler
  def to_s(__tplio__ : IO)
  end

  macro template(&blk)
    def to_s(__tplio__ : IO)
      capture_elems {{blk}}
    end
  end

  {% for tag_name in CONTENT_TAG_NAMES %}
    macro {{tag_name.id}}(css_class = nil, attrs = {} of String => String, &block)
      tag(__tplio__, {{tag_name}}, \{{css_class}}, \{{attrs}}) \{{block}}
    end
  {% end %}

  {% for tag_name in STANDALONE_TAG_NAMES %}
    macro {{tag_name.id}}(css_class = nil, attrs = {} of String => String)
      standalone_tag(__tplio__, {{tag_name}}, \{{css_class}}, \{{attrs}})
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

  def standalone_tag(io, name, css_class, attrs)
    tag_begin(io, name, css_class, attrs)
    io << "\>"
  end

  @[AlwaysInline]
  def tag_begin(io : IO, name : String, css_class : CSS::CSSClass.class | Nil, attrs : Hash(String, String))
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
  end

  @[AlwaysInline]
  def start_tag(io, name, css_class, attrs)
    tag_begin(io, name, css_class, attrs)
    io << ">"
  end

  @[AlwaysInline]
  def end_tag(io : IO, name : String)
    io << "</"
    io << name
    io << ">\n"
  end
end
