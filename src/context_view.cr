module Crumble::ContextView
  macro included
    getter ctx : Server::RequestContext

    def initialize(**args : **T) forall T
      {% verbatim do %}
        {% for key in T.keys.map(&.id) %}
          {% if ivar = @type.instance_vars.find { |iv| iv.id == key } %}
            unless (%arg{key} = args[{{key.symbolize}}]).nil?
              @{{key}} = %arg{key}
            else
              {% unless ivar.type.nilable? || ivar.has_default_value? %}
                raise "{{key}} can not be nil"
              {% end %}
            end
          {% end %}
        {% end %}
      {% end %}
    end
  end

  macro template(&blk)
    ToHtml.instance_template {{blk}}
  end
end
