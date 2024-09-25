require "yaml"

class Crumble::Server::Session
  include YAML::Serializable

  getter id : SessionKey

  def initialize(@id); end

  def initialize
    @id = SessionKey.generate
  end

  def update!(**attrs : **T) forall T
    {% for key in T.keys.map(&.id) %}
      {% unless @type.has_method?("#{key}=") %}
        {% raise "Not a #{@type.name} property: #{key}" %}
      {% end %}

      self.{{key}} = attrs[{{key.symbolize}}]
    {% end %}
  end
end

require "./session/timestamps"
