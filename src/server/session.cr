require "./session_store"

class Crumble::Server::Session
  annotation NoSetter; end

  @[NoSetter]
  getter id : SessionKey
  @[NoSetter]
  private getter session_store : SessionStore

  def initialize(@session_store, @id)
  end

  def initialize(@session_store)
    @id = SessionKey.generate
  end

  def update!(**attrs)
    if (error_attrs = (attrs.keys.to_a - {{ @type.instance_vars.select { |v| !v.annotation(NoSetter) }.map &.name.symbolize }} )).any?
      raise ArgumentError.new("Not a Session property: #{error_attrs}")
    end

    {% for var in @type.instance_vars.select { |v| !v.annotation(NoSetter) } %}
      if attrs.has_key?({{var.name.symbolize}})
        self.{{var.name}} = attrs[{{var.name.symbolize}}]?
      end
    {% end %}

    session_store.set(self)
  end
end
