require "../asset_file"
require "../template"
require "../js/*"

JavascriptFile.register "assets/stimulus.js", "#{__DIR__}/../../assets/stimulus.js"

abstract class JavascriptEvent < JS::CallContext
  def self.to_s(io : IO)
    io << name.chomp("Event").dasherize
  end
end

class ClickEvent < JavascriptEvent
end

class LoadEvent < JavascriptEvent
end

class FetchEvent < JavascriptEvent
  def respondWith(response)
    resolve_call("respondWith", response)
  end

  def request
    forward(JS::RequestContext, "request")
  end
end

abstract class StimulusController
  record Target, controller : StimulusController.class, name : String do
    def to_tag_attr
      {"data-#{controller.controller_name}-target", name}
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

  record Value, controller : StimulusController.class, name : String, value : String | Bool do
    def to_tag_attr
      {"data-#{controller.controller_name}-#{name}-value", value}
    end

    def selector
      CSS::AttrSelector.new(to_tag_attr.first, value.to_s)
    end
  end

  class Values
    @arr = [] of String

    def <<(value)
      @arr << value
    end

    def to_s(io : IO)
      io << "  static values = {"
      io << @arr.map do |value|
        "#{value}: String"
      end.join(", ")
      io << "}\n"
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

  record Action, event : JavascriptEvent.class, controller : StimulusController.class, method : Method do
    def to_tag_attr
      {"data-action", -> (io : IO) {
        io << event
        io << "->"
        io << controller.controller_name
        io << "#"
        io << method.name
      }}
    end
  end

  # exists to write JS null from within a crystal hash
  class NullContext
    def self.inspect(io : IO)
      io << "null"
    end
  end

  class GeneralControllerContext < JS::CallContext
    def dispatch(event : JavascriptEvent.class, target : JS::CallContext)
      resolve_call("dispatch", event.to_s.dump, {target: target, prefix: NullContext})
    end

    def element
      forward(JS::ElementContext, "element")
    end
  end

  @@targets = Targets.new
  @@values = Values.new
  @@methods = Methods.new

  def self.to_s(io : IO)
    io << "Stimulus.register(\""
    io << controller_name
    io << "\", class extends Controller {\n"
    io << @@targets
    io << @@values
    io << "\n"
    io << @@methods
    io << "\n})"
  end

  macro inherited
    private class ControllerContext < GeneralControllerContext
    end

    private class ControllerMethodContext < JS::WindowContext
      def this
        forward(ControllerContext, "this")
      end
    end
  end

  macro targets(*targets)
    {% for target_name in targets %}
      def self.{{target_name.id}}_target
        Target.new(self, "{{target_name.id}}")
      end

      private class ControllerContext
        def {{target_name.camelcase(lower: true).id}}Target
          forward(JS::ElementContext, "{{target_name.camelcase(lower: true).id}}Target")
        end
      end

      @@targets << {{target_name.id}}_target
    {% end %}
  end

  macro values(*values)
    {% for value_name in values %}
      def self.{{value_name.id}}_value(value_attr : Crumble::ORM::Attribute)
        Value.new(self, {{value_name.id.stringify}}, value_attr.value)
      end

      def self.{{value_name.id}}_value(value)
        Value.new(self, {{value_name.id.stringify}}, value)
      end

      private class ControllerContext
        def {{value_name.camelcase(lower: true).id}}Value
          forward(JS::StringContext, "{{value_name.id}}Value")
        end

        def {{value_name.camelcase(lower: true).id}}Value=(new_val)
          resolve_assignment("{{value_name.id}}Value", new_val)
        end
      end

      @@values << {{value_name.id.stringify}}
    {% end %}
  end

  macro method(name, &blk)
    @@{{name.id}}_method = Method.new(
      name: {{name.id.stringify}},
      body: String.build do |codeio|
        JS.capture ControllerMethodContext, 1, "codeio" {{blk}}
      end
    )

    private class ControllerContext
      def {{name.id}}(*args)
        forward_call(JS::StringContext, "{{name.id}}", *args)
      end
    end

    def self.{{name.id}}_action(event)
      Action.new(event, self, @@{{name.id}}_method)
    end

    @@methods << @@{{name.id}}_method
  end

  def self.controller_name
    self.name.chomp("Controller").gsub("::", "--").dasherize
  end

  def self.to_tag_attr
    {"data-controller", self.controller_name}
  end

  def self.selector
    CSS::AttrSelector.new("data-controller", self.controller_name)
  end
end

class Template
  macro stimulus_include(code)
    capture_elems do
      script({"type", "module"}) do
        {{code}}
      end
    end
  end
end
