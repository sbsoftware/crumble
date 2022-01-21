require "./*"

class Template
  CONTENT_TAG_NAMES = %w(html head title script body nav ul li a div p strong i form aside main section header h1 h2 h3 h4 h5 h6 table thead tbody tr td)
  STANDALONE_TAG_NAMES = %w(link img br)

  alias DockingPoint = String | Template | Nil

  property main_docking_point : DockingPoint = nil

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
      {% if (CONTENT_TAG_NAMES + STANDALONE_TAG_NAMES + %w(style stimulus_include)).includes?(blk.body.name.stringify) && blk.body.receiver.nil? %}
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
        {% if blk.body.block %}
          {{blk.body.receiver}}.{{blk.body.name}} do |{{blk.body.block.args.splat}}|
            capture_elems {{blk.body.block}}
          end
        {% else %}
          __tplio__ << {{blk.body}}
        {% end %}
      {% end %}
    {% elsif blk.body.is_a?(StringLiteral) %}
      __tplio__ << {{blk.body + "\n"}}
    {% elsif blk.body.is_a?(StringInterpolation) %}
      __tplio__ << {{blk.body}}
      __tplio__ << "\n"
    {% elsif blk.body.is_a?(Path) || blk.body.is_a?(MacroExpression) %}
      __tplio__ << {{blk.body}}
    {% else %}
      {{pp "Unknown node"}}
      {{pp blk.body}}
      {{pp blk.body.name}}
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
    macro {{tag_name.id}}(*attrs, &block)
      tag(__tplio__, {{tag_name}}, \{{attrs.splat}}) \{{block}}
    end
  {% end %}

  {% for tag_name in STANDALONE_TAG_NAMES %}
    macro {{tag_name.id}}(*attrs)
      standalone_tag(__tplio__, {{tag_name}}, \{{attrs.splat}})
    end
  {% end %}

  macro href(value)
    Href.new({{value}})
  end

  macro style(style_class)
    link(Rel::Stylesheet, href({{style_class}}.uri_path))
  end

  def tag(io, name, *attrs)
    start_tag(io, name, *attrs)
    io << "\n"
    yield(io)
    end_tag(io, name)
  end

  def tag(io, name, *attrs)
    start_tag(io, name, *attrs)
    end_tag(io, name)
  end

  def standalone_tag(io, name, *attrs)
    tag_begin(io, name, *attrs)
    io << "\>"
  end

  def tag_begin(io : IO, name : String)
    io << "<"
    io << name
  end

  def tag_begin(io : IO, name : String, arg)
    io << "<"
    io << name
    io << " "
    io << arg.html_attr_key
    io << "=\""
    arg.html_attr_value(io)
    io << "\""
  end

  def tag_begin(io : IO, name : String, *args)
    io << "<"
    io << name

    io_hash = Hash(String, String::Builder).new do |hash, key|
      hash[key] = String::Builder.new
    end
    args.reduce(io_hash) do |attrs, arg|
      attr_io = attrs[arg.html_attr_key]
      attr_io << " " unless attr_io.empty?
      arg.html_attr_value(attr_io)
      attrs
    end.each do |k, v|
      io << " "
      io << k
      io << "=\""
      io << v.to_s
      io << "\""
    end
  end

  def start_tag(io, name, *attrs)
    tag_begin(io, name, *attrs)
    io << ">"
  end

  def end_tag(io : IO, name : String)
    io << "</"
    io << name
    io << ">\n"
  end
end
