module Crumble
  abstract class Form
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

    def self.from_http_params(body : IO?)
      new(__http_params: body.try(&.gets_to_end) || "")
    end

    def self.new(*, __http_params : String)
      instance = allocate
      instance.initialize(__http_params: __http_params)
      GC.add_finalizer(instance) if instance.responds_to? :finalize
      instance
    end

    def initialize(*, __http_params : String)
      HTTP::Params.parse(__http_params) do |key, value|
        {% begin %}
        case key
          {% for var in @type.instance_vars.select { |iv| iv.annotation(Field) } %}
          when {{var.name.stringify}}
            @{{var.name}} = value
          {% end %}
        end
        {% end %}
      end
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
