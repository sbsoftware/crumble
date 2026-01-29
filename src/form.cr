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

    macro field(type_decl, *, type = nil, label = :__crumble_default__, &block)
      {% before_render_block = nil %}
      {% after_submit_block = nil %}

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
              {% statement.raise "before_render already defined for #{type_decl.var}" %}
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
              {% statement.raise "after_submit already defined for #{type_decl.var}" %}
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
        private def __before_render_{{type_decl.var}}({{before_render_block.args[0].id}} : {{type_decl.type}}) : {{type_decl.type}}
          {{before_render_block.body}}
        end
      {% end %}

      {% if after_submit_block %}
        private def __after_submit_{{type_decl.var}}({{after_submit_block.args[0].id}} : {{type_decl.type}}) : {{type_decl.type}}
          {{after_submit_block.body}}
        end
      {% end %}

      private def __apply_before_render_{{type_decl.var}}(value : {{type_decl.type}}?) : {{type_decl.type}}?
        {% if before_render_block %}
          {% if type_decl.type.resolve.nilable? %}
            __before_render_{{type_decl.var}}(value)
          {% else %}
            value.nil? ? nil : __before_render_{{type_decl.var}}(value)
          {% end %}
        {% else %}
          value
        {% end %}
      end

      private def __apply_after_submit_{{type_decl.var}}(value : {{type_decl.type}}?) : {{type_decl.type}}?
        {% if after_submit_block %}
          {% if type_decl.type.resolve.nilable? %}
            __after_submit_{{type_decl.var}}(value)
          {% else %}
            value.nil? ? nil : __after_submit_{{type_decl.var}}(value)
          {% end %}
        {% else %}
          value
        {% end %}
      end

      {% if label == :__crumble_default__ %}
        @[Field(type: {{(type || :text).id.symbolize}})]
      {% else %}
        @[Field(type: {{(type || :text).id.symbolize}}, label: {{label}})]
      {% end %}
      {% if type_decl.type.resolve.nilable? %}
        @[Nilable]
      {% end %}

      getter {{type_decl.var}} : {{type_decl.type}}?

      css_id {{type_decl.var.id.stringify.camelcase.id}}FieldId
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
          {% if ann.named_args.has_key?(:label) %}
            return {{ann.named_args[:label]}}
          {% else %}
            return default_label_caption(:{{ivar.name}})
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

        input {{@type}}::{{ivar.name.stringify.camelcase.id}}FieldId,
          type: {{ivar.annotation(Field)[:type]}},
          name: {{ivar.name.stringify}},
          value: __apply_before_render_{{ivar.name.id}}({{ivar.name.id}}).to_s
      {% end %}
    end
  end
end
