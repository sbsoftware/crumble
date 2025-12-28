require "uri/params/serializable"

module Crumble
  abstract class Form
    include URI::Params::Serializable

    annotation Field; end
    annotation Nilable; end

    getter errors : Array(String)?

    def initialize(**values : **T) forall T
      {% for key in T.keys.map(&.id) %}
        {% if ivar = @type.instance_vars.find { |iv| iv.name == key } %}
          @{{key}} = values[{{key.symbolize}}]
        {% else %}
          {% key.raise "Not a field: #{key}" %}
        {% end %}
      {% end %}
    end

    macro field(type_decl, *, type = nil)
      @[Field(type: {{(type || :text).id.symbolize}})]
      {% if type_decl.type.resolve.nilable? %}
        @[Nilable]
      {% end %}
      getter {{type_decl.var}} : {{type_decl.type}}?

      css_id {{type_decl.var.id.stringify.camelcase.id}}FieldId
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

    ToHtml.instance_template do
      {% for ivar in @type.instance_vars.select { |iv| iv.annotation(Field) } %}
        label {{@type}}::{{ivar.name.stringify.camelcase.id}}FieldId do
          {{ivar.name.stringify}}.capitalize
        end; input {{@type}}::{{ivar.name.stringify.camelcase.id}}FieldId, type: {{ivar.annotation(Field)[:type]}}, name: {{ivar.name.stringify}}, value: {{ivar.name.id}}.to_s
      {% end %}
    end
  end
end
