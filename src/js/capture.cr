module JS
  macro capture(call_context, level, io_name, &blk)
    {% if blk.body.is_a?(Expressions) %}
      {% for exp in blk.body.expressions %}
        JS.capture {{call_context}}, {{level}}, {{io_name}} do {{blk.args.size > 0 ? "|#{blk.args.splat}|".id : "".id}}
          {{exp}}
        end
      {% end %}
    {% else %}
      {% if blk.body.is_a?(Call) %}
        {{io_name.id}} << "  " * {{level + 1}}
        {{io_name.id}} << JS.resolve_call({{call_context}}, {{blk.body}}, {{level}}, {{blk.args.splat}})
        {% if level >= 0 %}
          {{io_name.id}} << "\n"
        {% end %}
      {% elsif blk.body.is_a?(If) %}
        {{io_name.id}} << "  " * {{level + 1}}
        {{io_name.id}} << "if ("
        JS.capture {{call_context}}, -1, {{io_name}} { {{blk.body.cond}} }
        {{io_name.id}} << ") {\n"
        JS.capture {{call_context}}, {{level + 1}}, {{io_name}} { {{blk.body.then}} }
        {{io_name.id}} << "\n"
        {{io_name.id}} << "  " * {{level + 1}}
        {{io_name.id}} << "}"
        {% if blk.body.else %}
          {{io_name.id}} << " else {\n"
          JS.capture {{call_context}}, {{level + 1}}, {{io_name}} { {{blk.body.else}} }
          {{io_name.id}} << "\n"
          {{io_name.id}} << "  " * {{level + 1}}
          {{io_name.id}} << "}"
        {% end %}
        {{io_name.id}} << "\n"
      {% elsif blk.body.is_a?(Path) %}
        {{io_name.id}} << "  " * {{level + 1}}
        {{io_name.id}} << "\""
        {{io_name.id}} << {{blk.body}}
        {{io_name.id}} << "\""
      {% elsif blk.body.is_a?(Return) %}
        {{io_name.id}} << "  " * {{level + 1}}
        {{io_name.id}} << "return "
        JS.capture {{call_context}}, {{level + 1}}, {{io_name}} { {{blk.body.exp}} }
      {% else %}
        {{ raise "Unknown node: #{blk.body}" }}
      {% end %}
    {% end %}
  end

  macro resolve_call(call_context, call, level, *block_args)
    {% if call.receiver %}
      {% if call.receiver.is_a?(Expressions) %}
        JS.resolve_call({{call_context}}, {{call.receiver.expressions.last}}, {{level}}, {{block_args.splat}}).{{call.name}}(*JS.resolve_call_args({{call_context}}, {{call}}, {{level}}, {{block_args.splat}})) {% if call.block %} do {{call.block.args.size > 0 ? "|#{call.block.args.splat}|".id : "".id}}
          String.build do |blockio_{{level}}|
            JS.capture({{call_context}}, {{level + 1}}, "blockio_{{level}}") {{call.block}}
          end
        end
        {% end %}
      {% elsif call.receiver.is_a?(Call) %}
        JS.resolve_call({{call_context}}, {{call.receiver}}, {{level}}, {{block_args.splat}}).{{call.name}}(*JS.resolve_call_args({{call_context}}, {{call}}, {{level}}, {{block_args.splat}})) {% if call.block %} do {{call.block.args.size > 0 ? "|#{call.block.args.splat}|".id : "".id}}
          String.build do |blockio_{{level}}|
            JS.capture({{call_context}}, {{level + 1}}, "blockio_{{level}}") {{call.block}}
          end
        end
        {% end %}
      {% else %}
        {% if block_args.includes?(call.receiver) %}
          {{call.receiver}}.{{call.name}}(*JS.resolve_call_args({{call_context}}, {{call}}, {{level}}, {{block_args.splat}}))
        {% else %}
          {{call_context}}.new.{{call.receiver}}.{{call.name}}(*JS.resolve_call_args({{call_context}}, {{call}}, {{level}}, {{block_args.splat}}))
        {% end %}
      {% end %}
    {% else %}
      {{call_context}}.new.{{call.name}}(*JS.resolve_call_args({{call_context}}, {{call}}, {{level}}, {{block_args.splat}}))
    {% end %}
  end

  macro resolve_call_args(call_context, call, level, *block_args)
    {% if call.args.size > 0 %}
      { {{call.args.map { |a| "JS.resolve_call_arg(#{call_context}, #{a}, #{block_args.splat})".id }.splat }} }
    {% else %}
      Tuple.new
    {% end %}
  end

  macro resolve_call_arg(call_context, arg, *block_args)
    {% if arg.is_a?(Call) %}
      {% if block_args.includes?(arg.name.id) || block_args.includes?(arg.receiver) %}
        {{arg}}
      {% else %}
        {{call_context}}.new.{{arg}}
      {% end %}
    {% elsif arg.is_a?(StringLiteral) %}
      {{arg.stringify}}
    {% else %}
      {{arg}}
    {% end %}
  end
end
