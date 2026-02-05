require "uri"
require "uri/params/from_www_form"

module Crumble
  abstract class Form
    annotation Field; end
    annotation Nilable; end

    getter ctx : Crumble::Server::HandlerContext
    getter errors : Array(String)?

    def initialize(@ctx : Crumble::Server::HandlerContext, **values : **T) forall T
      {% for key in T.keys.map(&.id) %}
        {% if ivar = @type.instance_vars.find { |iv| iv.name == key } %}
          {% if ivar.annotation(Field) %}
            @{{key}} = __apply_after_submit_{{key}}(values[{{key.symbolize}}])
          {% else %}
            @{{key}} = values[{{key.symbolize}}]
          {% end %}
        {% else %}
          {% key.raise "Not a field: #{key}" %}
        {% end %}
      {% end %}
    end

    def self.from_www_form(ctx : Crumble::Server::HandlerContext, www_form : ::String) : self
      from_www_form(ctx, ::URI::Params.parse(www_form))
    end

    def self.from_www_form(ctx : Crumble::Server::HandlerContext, params : ::URI::Params) : self
      {% begin %}
        {% for ivar in @type.instance_vars.select { |iv| iv.annotation(Field) } %}
          %field{ivar.name} = {{ivar.type}}.from_www_form(params, {{ivar.name.stringify}})
        {% end %}

        new(ctx,
          {% for ivar in @type.instance_vars.select { |iv| iv.annotation(Field) } %}
            {{ivar.name.id}}: %field{ivar.name},
          {% end %}
        )
      {% end %}
    end

    macro field(type_decl, *, type = nil, label = :__crumble_default__, attrs = nil, allow_blank = true, &block)
      {% before_render_block = nil %}
      {% after_submit_block = nil %}
      {% field_name = nil %}
      {% field_type = nil %}
      {% field_attr_nodes = [] of ASTNode %}

      {% unless type_decl.is_a?(TypeDeclaration) %}
        {% type_decl.raise "Field must use a type declaration, e.g. field name : String" %}
      {% end %}

      {% field_name = type_decl.var %}
      {% field_type = type_decl.type %}

      {% if attrs.is_a?(NilLiteral) %}
        {% field_attr_nodes = [] of ASTNode %}
      {% elsif attrs.is_a?(ArrayLiteral) || attrs.is_a?(TupleLiteral) %}
        {% for attr in attrs %}
          {% if attr.is_a?(NamedTupleLiteral) %}
            {% for key, value in attr %}
              {% field_attr_nodes << {key.id.stringify, value} %}
            {% end %}
          {% else %}
            {% field_attr_nodes << attr %}
          {% end %}
        {% end %}
      {% elsif attrs.is_a?(NamedTupleLiteral) %}
        {% for key, value in attrs %}
          {% field_attr_nodes << {key.id.stringify, value} %}
        {% end %}
      {% else %}
        {% field_attr_nodes << attrs %}
      {% end %}

      {% if block %}
        {% if block.body.is_a?(Expressions) %}
          {% statements = block.body.expressions %}
        {% elsif block.body.is_a?(NilLiteral) %}
          {% statements = [] of ASTNode %}
        {% else %}
          {% statements = [block.body] %}
        {% end %}

        {% for statement in statements %}
          {% if statement.is_a?(Call) && statement.name == "before_render" %}
            {% if before_render_block %}
              {% statement.raise "before_render already defined for #{field_name}" %}
            {% end %}
            {% unless statement.block %}
              {% statement.raise "before_render must have a block" %}
            {% end %}
            {% if statement.block.args.size != 1 %}
              {% statement.raise "before_render must accept exactly one argument" %}
            {% end %}
            {% before_render_block = statement.block %}
          {% elsif statement.is_a?(Call) && statement.name == "after_submit" %}
            {% if after_submit_block %}
              {% statement.raise "after_submit already defined for #{field_name}" %}
            {% end %}
            {% unless statement.block %}
              {% statement.raise "after_submit must have a block" %}
            {% end %}
            {% if statement.block.args.size != 1 %}
              {% statement.raise "after_submit must accept exactly one argument" %}
            {% end %}
            {% after_submit_block = statement.block %}
          {% else %}
            {% statement.raise "Only before_render and after_submit are allowed in a field block" %}
          {% end %}
        {% end %}
      {% end %}

      {% if before_render_block %}
        private def __before_render_{{field_name.id}}({{before_render_block.args[0].id}} : {{field_type}}) : {{field_type}}
          {{before_render_block.body}}
        end
      {% end %}

      {% if after_submit_block %}
        private def __after_submit_{{field_name.id}}({{after_submit_block.args[0].id}} : {{field_type}}) : {{field_type}}
          {{after_submit_block.body}}
        end
      {% end %}

      private def __apply_before_render_{{field_name.id}}(value : {{field_type}}?) : {{field_type}}?
        {% if before_render_block %}
          {% if field_type.resolve.nilable? %}
            __before_render_{{field_name.id}}(value)
          {% else %}
            value.nil? ? nil : __before_render_{{field_name.id}}(value)
          {% end %}
        {% else %}
          value
        {% end %}
      end

      private def __apply_after_submit_{{field_name.id}}(value : {{field_type}}?) : {{field_type}}?
        {% if after_submit_block %}
          {% if field_type.resolve.nilable? %}
            __after_submit_{{field_name.id}}(value)
          {% else %}
            value.nil? ? nil : __after_submit_{{field_name.id}}(value)
          {% end %}
        {% else %}
          value
        {% end %}
      end

      @[Field(
        type: {{(type || :text).id.symbolize}},
        allow_blank: {{allow_blank}},
        label: {{label}},
        attrs: {% if field_attr_nodes.empty? %}[] of Nil{% else %}[{{field_attr_nodes.splat}}]{% end %},
      )]
      {% if field_type.resolve.nilable? %}
        @[Nilable]
      {% end %}

      getter {{field_name}} : {{field_type}}?

      css_id {{field_name.id.stringify.camelcase.id}}FieldId
    end

    # Returns the label caption for a field when no explicit `label:` was passed
    # to the `field` macro. Override to customize default label behavior (e.g.
    # perform an I18n lookup).
    macro default_label_caption(field)
      {{field}}.to_s.capitalize
    end

    protected def label_caption_for(field : Symbol) : String?
      {% for ivar in @type.instance_vars.select { |iv| iv.annotation(Field) } %}
        if field == :{{ivar.name}}
          {% ann = ivar.annotation(Field) %}
          {% label_value = ann.named_args[:label] %}
          {% if label_value == :__crumble_default__ %}
            {% if ann[:type] == :hidden %}
              return nil
            {% else %}
              return default_label_caption(:{{ivar.name}})
            {% end %}
          {% else %}
            return {{label_value}}
          {% end %}
        end
      {% end %}
    end

    def valid?
      if errors = @errors
        return errors.none?
      else
        errors = @errors = [] of String
      end

      {% for var in @type.instance_vars.select { |iv| iv.annotation(Field) } %}
        %field{var} = @{{var}}

        {% unless var.annotation(Nilable) %}
          if %field{var}.nil?
            errors << {{var.stringify}}
          end
        {% end %}

        {% ann = var.annotation(Field) %}
        {% if ann.named_args.has_key?(:allow_blank) && ann.named_args[:allow_blank] == false %}
          if %field{var}.is_a?(String)
            if %field{var}.empty?
              errors << {{var.stringify}}
            end
          end
        {% end %}
      {% end %}

      errors.none?
    end

    def values
      {% begin %}
        {% fields = @type.instance_vars.select { |iv| iv.annotation(Field) } %}
        {% for var in fields %}
          %field{var.name} = @{{var}}

          {% unless var.annotation(Nilable) %}
            if %field{var.name}.nil?
              raise "@{{var}} must not be nil!"
            end
          {% end %}
        {% end %}
        {% if fields.empty? %}
          NamedTuple.new
        {% else %}
          {
            {% for var in fields %}
              {{var}}: %field{var.name},
            {% end %}
          }
        {% end %}
      {% end %}
    end

    ToHtml.instance_template do
      {% for ivar in @type.instance_vars.select { |iv| iv.annotation(Field) } %}
        if %label_caption = label_caption_for(:{{ivar.name}})
          label {{@type}}::{{ivar.name.stringify.camelcase.id}}FieldId do
            %label_caption
          end
        end

        {% ann = ivar.annotation(Field) %}
        {% attrs = ann.named_args[:attrs] %}
        input {{@type}}::{{ivar.name.stringify.camelcase.id}}FieldId{% if attrs.size > 0 %}, {{attrs.splat}}{% end %},
          type: {{ann[:type]}},
          name: {{ivar.name.stringify}},
          value: __apply_before_render_{{ivar.name.id}}({{ivar.name.id}}).to_s
      {% end %}
    end
  end
end
