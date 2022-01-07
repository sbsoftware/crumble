require "../asset_file"
require "../template"

JavascriptFile.register "assets/stimulus.js", "#{__DIR__}/../../assets/stimulus.js"

abstract class JavascriptEvent
  def self.to_s(io : IO)
    io << name.dasherize
  end
end

record Target, controller : StimulusController.class, name : String do
  def html_attr_key
    "data-#{controller.controller_name}-target"
  end

  def html_attr_value(io)
    io << name
  end
end

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
    "#{receiver_dot(name)}(#{args.join(", ")})"
  end

  def resolve_attr(name)
    receiver_dot(name)
  end

  def forward(ctx_class, next_receiver)
    ctx_class.new(receiver_dot(next_receiver))
  end

  def to_s(io : IO)
    io << @receiver
  end

  def inspect(io : IO)
    io << @receiver
  end

  def receiver_dot(call)
    @receiver.blank? ? call : "#{@receiver}.#{call}"
  end
end

# exists to write JS null from within a crystal hash
class NullContext
  def self.inspect(io : IO)
    io << "null"
  end
end

class MethodContext < CallContext
  def window
    forward(ElementContext, "window")
  end

  def console
    forward(ConsoleContext, "console")
  end
end

class ControllerContext < CallContext
  def dispatch(event : JavascriptEvent.class, target : ElementContext)
    resolve_call("dispatch", event.to_s.dump, {target: target, prefix: NullContext})
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

  def classList
    forward(ClassListContext, "classList")
  end
end

class ClassListContext < CallContext
  def toggle(klass : CSS::CSSClass.class)
    resolve_call("toggle", klass.to_s.dump)
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
        {% if blk.body.receiver %}
          codeio << {{call_context}}.new.{{blk.body.receiver.id}}.{{blk.body.name}}({{blk.body.args.map { |a| a.is_a?(Call) ? "#{call_context}.new.#{a}".id : (a.is_a?(StringLiteral) ? a.stringify : a) }.splat }})
        {% else %}
          codeio << {{call_context}}.new.{{blk.body.name}}({{blk.body.args.map { |a| a.is_a?(Call) ? "#{call_context}.new.#{a}".id : (a.is_a?(StringLiteral) ? a.stringify : a) }.splat }})
        {% end %}
      {% else %}
        {{ raise "Unknown node: #{blk.body}" }}
      {% end %}
      codeio << "\n"
    {% end %}
  end

  macro inherited
    private class {{@type.name.id}}ControllerContext < ControllerContext
    end

    private class {{@type.name.id}}ControllerMethodContext < MethodContext
      def this
        forward({{@type.name.id}}ControllerContext, "this")
      end
    end
  end

  macro targets(*targets)
    {% for target_name in targets %}
      def self.{{target_name.id}}_target
        Target.new(self, "{{target_name.id}}")
      end

      private class {{@type.name.id}}ControllerContext
        def {{target_name.camelcase(lower: true).id}}Target
          forward(ElementContext, "{{target_name.camelcase(lower: true).id}}Target")
        end
      end

      @@targets << {{target_name.id}}_target
    {% end %}
  end

  macro method(name, &blk)
    @@methods << Method.new(
      name: {{name}},
      body: String.build do |codeio|
        capture_code {{@type.name.id}}ControllerMethodContext {{blk}}
      end
    )
  end

  def self.controller_name
    self.name.chomp("Controller").gsub("::", "--").dasherize
  end

  def self.html_attr_key
    "data-controller"
  end

  def self.html_attr_value(io)
    io << self.controller_name
  end
end

class Template
  macro stimulus_include(code)
    capture_elems do
      script TagAttr.new("type", "module") do
        {{code}}
      end
    end
  end
end
