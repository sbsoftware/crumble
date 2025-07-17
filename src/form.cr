require "uri/params/serializable"

module Crumble
  abstract class Form
    include URI::Params::Serializable

    annotation Field; end
    annotation Nilable; end

    getter errors : Array(String)?

    macro field(type_decl)
      @[Field]
      {% if type_decl.type.resolve.nilable? %}
        @[Nilable]
      {% end %}
      getter {{type_decl.var}} : {{type_decl.type}}?
    end

    def valid?
      if errors = @errors
        return errors.none?
      else
        errors = @errors = [] of String
      end

      {% for var in @type.instance_vars.select { |iv| iv.annotation(Field) } %}
        {% unless var.annotation(Nilable) %}
          if (%field{var} = @{{var}}).nil?
            errors << {{var.stringify}}
          end
        {% end %}
      {% end %}

      errors.none?
    end

    def values
      {% begin %}
        {% for var in @type.instance_vars.select { |iv| iv.annotation(Field) } %}
          %field{var.name} = @{{var}}

          {% unless var.annotation(Nilable) %}
            if %field{var.name}.nil?
              raise "@{{var}} must not be nil!"
            end
          {% end %}
        {% end %}
        {
          {% for var in @type.instance_vars.select { |iv| iv.annotation(Field) } %}
            {{var}}: %field{var.name},
          {% end %}
        }
      {% end %}
    end
  end
end
