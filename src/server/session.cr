require "yaml"

class Crumble::Server::Session
  include YAML::Serializable

  annotation NoSetter; end

  @[NoSetter]
  getter id : SessionKey

  def initialize(@id); end

  def initialize
    @id = SessionKey.generate
  end

  def update!(**attrs)
    if (error_attrs = (attrs.keys.to_a - {{ @type.instance_vars.select { |v| !v.annotation(NoSetter) }.map(&.name.symbolize).stringify.+(" of Symbol").id }} )).any?
      raise ArgumentError.new("Not a Session property: #{error_attrs}")
    end

    {% for var in @type.instance_vars.select { |v| !v.annotation(NoSetter) } %}
      if attrs.has_key?({{var.name.symbolize}})
        self.{{var.name}} = attrs[{{var.name.symbolize}}]?
      end
    {% end %}
  end
end

require "./session/timestamps"
