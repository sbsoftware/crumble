require "./tag_attrs"

class Template
  CONTENT_TAG_NAMES = %w(html head title body nav ul li a div strong form aside main section header h1)
  STANDALONE_TAG_NAMES = %w(link img)

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
      {% if (CONTENT_TAG_NAMES + STANDALONE_TAG_NAMES + %w(style resource_link)).includes?(blk.body.name.stringify) && blk.body.receiver.nil? %}
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
    {% else %}
      {{pp "Unknown node"}}
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
    macro {{tag_name.id}}(*attrs, &block)
      tag(__tplio__, {{tag_name}}, \{{attrs.splat}}) \{{block}}
    end
  {% end %}

  {% for tag_name in STANDALONE_TAG_NAMES %}
    macro {{tag_name.id}}(*attrs)
      standalone_tag(__tplio__, {{tag_name}}, \{{attrs.splat}})
    end
  {% end %}

  macro style(style_class)
    link(TagAttrs.new({"rel" => "stylesheet", "href" => {{style_class}}.uri_path}))
  end

  macro resource_link(res, caption)
    a(TagAttrs.new({"href" => {{res}}.uri_path})) do
      capture_elems do
        {{caption}}
      end
    end
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

  def tag_begin(io : IO, name : String, *attrs : (CSS::ElementId.class | CSS::CSSClass.class | Template::TagAttrs))
    io << "<"
    io << name

    class_io = String::Builder.new
    idWritten = false

    attrs.each do |attr|
      case attr
      in CSS::ElementId.class
        raise "Element #{name} already has an ID. Cannot write #{attr}" if idWritten

        io << " id=\""
        io << attr
        io << "\""

        idWritten = true
      in CSS::CSSClass.class
        class_io << " " unless class_io.empty?
        class_io << attr
      in Template::TagAttrs
        attr.each do |(k, v)|
          io << " "
          io << k
          io << "=\""
          io << v
          io << "\""
        end
      end
    end
    unless class_io.empty?
      io << " class=\""
      io << class_io.to_s
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
