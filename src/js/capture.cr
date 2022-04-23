module JS
  macro capture(call_context, level, io_name, *locals, &blk)
    {% if blk.body.is_a?(Expressions) %}
      {% for exp in blk.body.expressions %}
        JS.capture {{call_context}}, {{level}}, {{io_name}}, {{locals.splat}} do {{blk.args.size > 0 ? "|#{blk.args.splat}|".id : "".id}}
          {{exp}}
        end
      {% end %}
    {% else %}
      {% if blk.body.is_a?(Call) %}
        {{io_name.id}} << "  " * {{level + 1}}
        {{io_name.id}} << JS.resolve_call({{call_context}}, {{blk.body}}, {{level}}, {{locals.splat(", ")}}{{blk.args.splat}})
        {% if level >= 0 %}
          {{io_name.id}} << "\n"
        {% end %}
      {% elsif blk.body.is_a?(If) %}
        {{io_name.id}} << "  " * {{level + 1}}
        {{io_name.id}} << "if ("
        JS.capture {{call_context}}, -1, {{io_name}}, {{locals.splat}} do {{blk.args.size > 0 ? "|#{blk.args.splat}|".id : "".id}}
          {{blk.body.cond}}
        end
        {{io_name.id}} << ") {\n"
        JS.capture {{call_context}}, {{level + 1}}, {{io_name}}, {{locals.splat}} do {{blk.args.size > 0 ? "|#{blk.args.splat}|".id : "".id}}
          {{blk.body.then}}
        end
        {{io_name.id}} << "  " * {{level + 1}}
        {{io_name.id}} << "}"
        {% if blk.body.else %}
          {{io_name.id}} << " else {\n"
          JS.capture {{call_context}}, {{level + 1}}, {{io_name}}, {{locals.splat}} do {{blk.args.size > 0 ? "|#{blk.args.splat}|".id : "".id}}
            {{blk.body.else}}
          end
          {{io_name.id}} << "  " * {{level + 1}}
          {{io_name.id}} << "}"
        {% end %}
      {% elsif blk.body.is_a?(Path) %}
        {{io_name.id}} << "  " * {{level + 1}}
        {{io_name.id}} << "\""
        {{io_name.id}} << JS.resolve_path({{blk.body}})
        {{io_name.id}} << "\""
      {% elsif blk.body.is_a?(Return) %}
        {{io_name.id}} << "  " * {{level + 1}}
        {{io_name.id}} << "return "
        JS.capture {{call_context}}, {{level + 1}}, {{io_name}} { {{blk.body.exp}} }
      {% elsif blk.body.is_a?(RespondsTo) %}
        {{io_name.id}} << "\""
        {{io_name.id}} << {{blk.body.name}}
        {{io_name.id}} << "\" in "
        {{io_name.id}} << JS.resolve_call({{call_context}}, {{blk.body.receiver}}, {{level}})
      {% elsif blk.body.is_a?(Var) %}
        {{io_name.id}} << {{blk.body}}
      {% elsif blk.body.is_a?(Assign) %}
        {{io_name.id}} << "var "
        {{io_name.id}} << {{blk.body.target.stringify}}
        {{io_name.id}} << " = "
        JS.capture({{call_context}}, -1, {{io_name}}, {{locals.splat(", ")}}{{blk.args.splat}}) do
          {{blk.body.value}}
        end
        {{io_name.id}} << "\n"
        {% if blk.body.value.is_a?(Call) %}
          {{blk.body.target}} = JS.resolve_call({{call_context}}, {{blk.body.value}}, {{level}}, {{blk.args.splat}})
          if {{blk.body.target}}.responds_to?(:rename)
            {{blk.body.target}} = {{blk.body.target}}.rename({{blk.body.target.stringify}})
          end
        {% else %}
          {{blk.body}}
        {% end %}
      {% elsif blk.body.is_a?(StringLiteral) %}
        {{io_name.id}} << "\""
        {{io_name.id}} << {{blk.body}}
        {{io_name.id}} << "\""
      {% elsif blk.body.is_a?(Nop) %}
        # do nothing
      {% else %}
        {{pp blk.body.pipi}}
        {{ raise "Unknown node: #{blk.body}" }}
      {% end %}
    {% end %}
  end

  macro resolve_call(call_context, call, level, *block_args)
    JS.resolve_receiver({{call_context}}, {{call.receiver || nil}}, {{level}}, {{block_args.splat}}).{{call.name}}(*JS.resolve_call_args({{call_context}}, {{call}}, {{level}}, {{block_args.splat}})) {% if call.block %} do {{call.block.args.size > 0 ? "|#{call.block.args.splat}|".id : "".id}}
      String.build do |blockio_{{level}}|
        JS.capture({{call_context}}, {{level + 1}}, "blockio_{{level}}", {{block_args.splat}}) {{call.block}}
      end
    end
    {% end %}
  end

  macro resolve_receiver(call_context, recv, level, *block_args)
    {% if recv %}
      {% if recv.is_a?(Expressions) %}
        JS.resolve_call({{call_context}}, {{recv.expressions.last}}, {{level}}, {{block_args.splat}})
      {% elsif recv.is_a?(Call) %}
        JS.resolve_call({{call_context}}, {{recv}}, {{level}}, {{block_args.splat}})
      {% elsif recv.is_a?(Path) %}
        JS.resolve_path({{recv}})
      {% elsif block_args.includes?(recv) || recv.is_a?(Var) %}
        {{recv}}
      {% elsif recv.is_a?(NumberLiteral) %}
        JS::NumberContext.new({{recv.stringify}})
      {% else %}
        {{call_context}}.new.{{recv}}
      {% end %}
    {% else %}
      {{call_context}}.new
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
      {% if block_args.includes?(arg.name.id) || block_args.includes?(arg.receiver) || arg.receiver.is_a?(Path) %}
        {{arg}}
      {% else %}
        JS.resolve_call({{call_context}}, {{arg}}, 0, {{block_args.splat}})
      {% end %}
    {% elsif arg.is_a?(StringLiteral) %}
      {{arg.stringify}}
    {% elsif arg.is_a?(Var) %}
      {{arg.stringify}}
    {% else %}
      {{arg}}
    {% end %}
  end

  macro resolve_path(path)
    {% if path.resolve? %}
      {{path}}
    {% else %}
      JS::{{path}}Context.new
    {% end %}
  end
end
