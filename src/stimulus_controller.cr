record Target, name : String

class Targets
  @arr = [] of Target

  def <<(target)
    @arr << target
  end

  def to_s(io : IO)
    io << "  static targets = ["
    io << @arr.map do |target|
      "\"#{target.name}\""
    end.join(", ")
    io << "]\n"
  end
end

record Method, name : String, body : String do
  def to_s(io : IO)
    io << "  "
    io << name
    io << "() {\n"
    io << body
    io << "  }"
  end
end

class Methods
  @methods = {} of String => Method

  def <<(method)
    @methods[method.name] = method
  end

  def to_s(io : IO)
    io << @methods.values.map(&.to_s).join("\n\n")
  end
end

abstract class CallContext
  @receiver : String

  def initialize(@receiver = "")
  end

  def resolve_call(name, *args)
    "#{@receiver}.#{name}(#{args.join(", ")})"
  end

  def resolve_attr(name)
    "#{@receiver}.#{name}"
  end

  def forward(ctx_class, receiver)
    ctx_class.new(@receiver.blank? ? receiver : "#{@receiver}.#{receiver}")
  end
end

class MethodContext < CallContext
  def console
    forward(ConsoleContext, "console")
  end

  def this
    forward(self.class, "this")
  end
end

class ConsoleContext < CallContext
  alias Loggable = String

  def log(*entries : Loggable)
    resolve_call("log", *entries)
  end
end

class ElementContext < CallContext
  def value
    resolve_attr("value")
  end

  def innerHTML
    resolve_attr("innerHTML")
  end
end

abstract class StimulusController
  @@targets = Targets.new
  @@methods = Methods.new

  def self.to_s(io : IO)
    io << "Stimulus.register(\""
    io << controller_name
    io << "\", class extends Controller {\n"
    io << @@targets
    io << @@methods
    io << "\n})"
  end

  macro capture_code(call_context, level = 1, &blk)
    {% if blk.body.is_a?(Expressions) %}
      {% for exp in blk.body.expressions %}
        capture_code {{call_context}}, {{level}} do
          {{exp}}
        end
      {% end %}
    {% else %}
      codeio << "  " * {{level + 1}}
      {% if blk.body.is_a?(Call) %}
        codeio << {{call_context}}.new.{{blk.body.receiver.id}}.{{blk.body.name}}({{blk.body.args.map { |a| a.is_a?(Call) ? "#{call_context}.new.#{a}".id : a.stringify }.splat }})
      {% else %}
        {{ raise "Unknown node: #{blk.body}" }}
      {% end %}
      codeio << "\n"
    {% end %}
  end

  macro targets(*targets)
    {% for target_name in targets %}
      @@targets << Target.new("{{target_name.id}}")

      def {{target_name.id}}Target
        # TODO: Something that can be fed to tag macro calls
      end
    {% end %}
  end

  macro method(name, &blk)
    private class {{name.capitalize.id}}MethodContext < MethodContext
      {% for target_def in @type.methods.select { |m| m.name.ends_with?("Target") } %}
        def {{target_def.name.id}}
          forward(ElementContext, {{target_def.name.stringify}})
        end
      {% end %}
    end

    @@methods << Method.new(
      name: {{name}},
      body: String.build do |codeio|
        capture_code {{name.capitalize.id}}MethodContext {{blk}}
      end
    )
  end

  def self.controller_name
    self.name.chomp("Controller").gsub("::", "--").dasherize
  end
end
