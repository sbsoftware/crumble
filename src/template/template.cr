require "./*"

class IO
  def <<(a_proc : Proc(IO, Nil))
    a_proc.call(self)
  end
end

macro template(method_name, &blk)
  private class {{method_name.id.stringify.camelcase.id}}Template < Template
    @parent : {{@type}}

    forward_missing_to @parent

    def initialize(@parent)
    end

    def initialize(@parent, @main_docking_point)
    end

    Template.template {{blk}}
  end

  def {{method_name.id}}
    {{method_name.id.stringify.camelcase.id}}Template.new(self)
  end

  def {{method_name.id}}(main_docking_point)
    {{method_name.id.stringify.camelcase.id}}Template.new(self, main_docking_point)
  end
end

class Template
  CONTENT_TAG_NAMES = %w(html head title script body nav ul li a div p strong i form aside main section header h1 h2 h3 h4 h5 h6 table thead tbody tr td span dl dt dd)
  STANDALONE_TAG_NAMES = %w(meta link img br input)

  alias DockingPoint = String | Template | Proc(IO, Nil) | Nil

  property main_docking_point : DockingPoint = nil

  def initialize
  end

  def initialize(@main_docking_point)
  end

  macro capture_elems(io_var = __tplio__, &blk)
    {% if blk %}
      {% if blk.body.is_a?(Expressions) %}
        {% for exp in blk.body.expressions %}
          eval_exp({{io_var}}) do
            {{exp}}
          end
        {% end %}
      {% else %}
        eval_exp({{io_var}}) {{blk}}
      {% end %}
    {% end %}
  end

  macro eval_exp(io_var = __tplio__, &blk)
    {% if blk.body.is_a?(Call) %}
      {% if (CONTENT_TAG_NAMES + STANDALONE_TAG_NAMES + %w(doctype style template_tag stimulus_include)).includes?(blk.body.name.stringify) && blk.body.receiver.nil? %}
        {% if blk.body.block %}
          {% if blk.body.named_args && blk.args.size > 0 %}
            {{blk.body.name}}({{blk.body.args.splat}}, {{blk.body.named_args.splat}}) do
          {% elsif blk.body.named_args && blk.args.empty? %}
            {{blk.body.name}}({{blk.body.named_args.splat}}) do
          {% else %}
            {{blk.body.name}}({{blk.body.args.splat}}) do
          {% end %}
            capture_elems({{io_var}}) {{blk.body.block}}
          end
        {% else %}
          {{blk.body}}
        {% end %}
      {% else %}
        {% if blk.body.block %}
          {% if blk.body.name.stringify == "within" %}
            within({{blk.body.args.splat}}) do
              capture_elems(__withinio__) {{blk.body.block}}
            end
          {% elsif blk.body.name.stringify == "_extract_blk_call" %}
            {{blk.body}}
          {% else %}
            {{blk.body.receiver}}.{{blk.body.name}} do |{{blk.body.block.args.splat}}|
              capture_elems({{io_var}}) {{blk.body.block}}
            end
          {% end %}
        {% else %}
          %call = {{blk.body}}
          if %call.is_a?(Crumble::ORM::Attribute)
            {{io_var}} << %call.value
          else
            {{io_var}} << %call
          end
        {% end %}
      {% end %}
    {% elsif blk.body.is_a?(StringLiteral) %}
      {{io_var}} << {{blk.body}}
    {% elsif blk.body.is_a?(StringInterpolation) %}
      {{io_var}} << {{blk.body}}
    {% elsif blk.body.is_a?(Path) || blk.body.is_a?(MacroExpression) || blk.body.is_a?(InstanceVar) || blk.body.is_a?(Var) %}
      {{io_var}} << {{blk.body}}
    {% elsif blk.body.is_a?(Nop) %}
      # do nothing
    {% else %}
      {{pp "Unknown node"}}
      {{pp blk.body}}
      {{pp blk.body.stringify}}
    {% end %}
  end

  macro template(&blk)
    def to_s(__tplio__ : IO)
      capture_elems(__tplio__) {{blk}}
    end
  end

  macro _extract_blk_call(call_name, &blk)
    {% if blk.body.is_a?(Expressions) %}
      {% for exp in blk.body.expressions %}
        {% if exp.is_a?(Call) && exp.name.id == call_name.id && exp.block %}
          {{exp.block.body}}
        {% end %}
      {% end %}
    {% else %}
      {% if blk.body.is_a?(Call) && blk.body.name.id == call_name.id && blk.body.block %}
        {{blk.body.block.body}}
      {% end %}
    {% end %}
  end

  macro within(tpl, &blk)
    {% if tpl.is_a?(Path) %}
      %tpl = {{tpl}}.new
    {% else %}
      %tpl = {{tpl}}
    {% end %}
    %tpl.main_docking_point = -> (__withinio__ : IO) : Nil do
      {{blk.body}}
    end
    __tplio__ << %tpl
  end

  macro finished
    {% for tag_name in CONTENT_TAG_NAMES %}
      macro {{tag_name.id}}(*attrs, &block)
        tag(__tplio__, {{tag_name.gsub(/_/, "-")}}, \{{attrs.splat}}) \{{block}}
      end
    {% end %}

    {% for tag_name in STANDALONE_TAG_NAMES %}
      macro {{tag_name.id}}(*attrs)
        standalone_tag(__tplio__, {{tag_name.gsub(/_/, "-")}}, \{{attrs.splat}})
      end
    {% end %}
  end

  macro doctype(dt = "html")
    __tplio__ << "<!doctype "
    __tplio__ << {{dt.id.stringify}}
    __tplio__ << ">\n"
  end

  macro template_tag(*attrs, &block)
    tag(__tplio__, "template", {{attrs.splat}}) {{block}}
  end

  macro href(value)
    {"href", {{value}}}
  end

  macro action(value)
    FormAction.new({{value}})
  end

  macro style(style_class)
    link(Rel::Stylesheet, href({{style_class}}.uri_path))
  end

  def tag(io, name, *attrs)
    start_tag(io, name, *attrs)
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

  def tag_begin(io : IO, name : String, *args)
    io << "<"
    io << name

    io_hash = Hash(String, String::Builder).new do |hash, key|
      hash[key] = String::Builder.new
    end
    args.reduce(io_hash) do |attrs, arg|
      eval_tag_attr(attrs, arg)
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

  def eval_tag_attr(attrs, current) : Nil
    return eval_tag_attr(attrs, current.to_tag_attr) if current.responds_to? :to_tag_attr

    attr_io = attrs[current[0]]
    attr_io << " " unless attr_io.empty?
    val = current[1]
    case val
    when Proc(IO, IO)
      val.call(attr_io)
    else
      attr_io << val
    end
  end
end
