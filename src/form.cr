require "uri"
require "uri/params/from_www_form"

module Crumble
  # Generic class for form field wrappers. Defined as a css_class so it can be
  # referenced from CSS builder code (e.g. `rule Crumble::Field do ... end`).
  css_class Field
  css_class FormErrors
  css_class FieldErrors

  abstract class Form
    annotation Field; end
    annotation Nilable; end

    getter ctx : Crumble::Server::HandlerContext
    @submitted : Bool
    @validation_error_target : Symbol? = nil
    @errors : Array(Tuple(Symbol, String))? = nil

    def initialize(ctx : Crumble::Server::HandlerContext, **values : **T) forall T
      initialize(ctx, false, **values)
    end

    def initialize(@ctx : Crumble::Server::HandlerContext, @submitted : Bool, **values : **T) forall T
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

    def submitted? : Bool
      @submitted
    end

    def errors : Array(String)?
      @errors.try(&.map(&.[1]))
    end

    def error_entries : Array(Tuple(Symbol, String))?
      @errors
    end

    def self.from_www_form(ctx : Crumble::Server::HandlerContext, www_form : ::String) : self
      from_www_form(ctx, ::URI::Params.parse(www_form))
    end

    def self.from_www_form(ctx : Crumble::Server::HandlerContext, params : ::URI::Params) : self
      {% begin %}
        {% for ivar in @type.instance_vars.select { |iv| iv.annotation(Field) } %}
          %field{ivar.name} = {{ivar.type}}.from_www_form(params, {{ivar.name.stringify}})
        {% end %}

        new(ctx, true,
          {% for ivar in @type.instance_vars.select { |iv| iv.annotation(Field) } %}
            {{ivar.name.id}}: %field{ivar.name},
          {% end %}
        )
      {% end %}
    end

    macro validation(&block)
      {% unless block %}
        {% raise "validation must have a block" %}
      {% end %}
      {% if block.args.size > 0 %}
        {% block.raise "validation must not accept block arguments" %}
      {% end %}

      private def __run_form_validations
        {% if @type.has_method?("__run_form_validations") %}
          {% if @type.methods.map(&.name.id.stringify).includes?("__run_form_validations") %}
            previous_def
          {% else %}
            super
          {% end %}
        {% end %}

        __with_validation_error_target(:_base) do
          {{block.body}}
        end
      end
    end

    macro field(type_decl, *, type = nil, label = :__crumble_default__, attrs = nil, allow_blank = true, options = nil, &block)
      {% before_render_block = nil %}
      {% after_submit_block = nil %}
      {% validation_blocks = [] of ASTNode %}
      {% field_name = nil %}
      {% field_type = nil %}
      {% field_attr_nodes = [] of ASTNode %}
      {% field_control_type = (type || :text).id.symbolize %}

      {% unless type_decl.is_a?(TypeDeclaration) %}
        {% type_decl.raise "Field must use a type declaration, e.g. field name : String" %}
      {% end %}

      {% field_name = type_decl.var %}
      {% field_type = type_decl.type %}

      {% if field_control_type == :select %}
        {% if options.is_a?(NilLiteral) %}
          {% type_decl.raise "select field #{field_name} must define options: (e.g. options: {\"a\" => \"A\"} or options: [{\"a\", \"A\"}])" %}
        {% end %}
      {% else %}
        {% unless options.is_a?(NilLiteral) %}
          {% options.raise "options: is only supported for select fields (type: :select)" %}
        {% end %}
      {% end %}

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
          {% elsif statement.is_a?(Call) && statement.name == "validation" %}
            {% unless statement.block %}
              {% statement.raise "validation must have a block" %}
            {% end %}
            {% if statement.block.args.size != 0 %}
              {% statement.raise "validation must not accept block arguments" %}
            {% end %}
            {% validation_blocks << statement.block %}
          {% else %}
            {% statement.raise "Only before_render, after_submit, and validation are allowed in a field block" %}
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

      private def __run_field_validations_{{field_name.id}}
        {% for validation_block in validation_blocks %}
          __with_validation_error_target(:{{field_name.id}}) do
            {{validation_block.body}}
          end
        {% end %}
      end

      @[Field(
        type: {{field_control_type}},
        allow_blank: {{allow_blank}},
        label: {{label}},
        attrs: {% if field_attr_nodes.empty? %}[] of Nil{% else %}[{{field_attr_nodes.splat}}]{% end %},
        options: {{options}},
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
          {% if ann[:type] == :hidden %}
            return nil
          {% end %}

          {% label_value = ann.named_args[:label] %}
          {% if label_value == :__crumble_default__ %}
            return default_label_caption(:{{ivar.name}})
          {% else %}
            return {{label_value}}
          {% end %}
        end
      {% end %}
    end

    private def __run_form_validations
    end

    protected def add_error(message : String, field : Symbol? = nil) : Nil
      __add_error(field || @validation_error_target || :_base, message)
      nil
    end

    private def __with_validation_error_target(field : Symbol, &)
      previous_field = @validation_error_target
      @validation_error_target = field
      yield
    ensure
      @validation_error_target = previous_field
    end

    private def __add_error(field : Symbol, message : String)
      if errors = @errors
        errors << {field, message}
      else
        @errors = [{field, message}]
      end
    end

    private def __error_messages_for(field : Symbol) : Array(String)
      return [] of String unless errors = @errors
      errors.compact_map do |error|
        error[1] if error[0] == field
      end
    end

    def valid?
      return true unless submitted?
      if existing_errors = @errors
        return existing_errors.none?
      end
      @errors = [] of Tuple(Symbol, String)

      {% for var in @type.instance_vars.select { |iv| iv.annotation(Field) } %}
        %field{var} = @{{var}}

        {% unless var.annotation(Nilable) %}
          if %field{var}.nil?
            __add_error(:{{var.id}}, {{var.stringify}})
          end
        {% end %}

        {% ann = var.annotation(Field) %}
        {% if ann.named_args.has_key?(:allow_blank) && ann.named_args[:allow_blank] == false %}
          if %field{var}.is_a?(String)
            if %field{var}.empty?
              __add_error(:{{var.id}}, {{var.stringify}})
            end
          end
        {% end %}

        __run_field_validations_{{var.id}}
      {% end %}

      __run_form_validations
      @errors.not_nil!.none?
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
      if base_errors = __error_messages_for(:_base)
        if base_errors.size > 0
          div Crumble::FormErrors do
            ul do
              base_errors.each do |error|
                li do
                  error
                end
              end
            end
          end
        end
      end

      {% for ivar in @type.instance_vars.select { |iv| iv.annotation(Field) } %}
        {% ann = ivar.annotation(Field) %}
        {% attrs = ann.named_args[:attrs] %}
        {% control_type = ann[:type] %}
        {% if control_type == :hidden %}
          input {{@type}}::{{ivar.name.stringify.camelcase.id}}FieldId{% if attrs.size > 0 %}, {{attrs.splat}}{% end %},
            type: {{control_type}},
            name: {{ivar.name.stringify}},
            value: __apply_before_render_{{ivar.name.id}}({{ivar.name.id}}).to_s
        {% else %}
          div Crumble::Field do
            if %label_caption = label_caption_for(:{{ivar.name}})
              label {{@type}}::{{ivar.name.stringify.camelcase.id}}FieldId do
                %label_caption
              end
            end

            {% if control_type == :select %}
              {% options = ann.named_args[:options] %}
              select_tag {{@type}}::{{ivar.name.stringify.camelcase.id}}FieldId{% if attrs.size > 0 %}, {{attrs.splat}}{% end %},
                name: {{ivar.name.stringify}} do
                %selected_value = __apply_before_render_{{ivar.name.id}}({{ivar.name.id}}).to_s

                {{options}}.to_h.each do |%pair|
                  %option_value = %pair.first
                  %option_label = %pair.last

                  option value: %option_value.to_s, selected: (%selected_value == %option_value.to_s) do
                    %option_label.to_s
                  end
                end
              end
            {% elsif control_type == :textarea %}
              textarea {{@type}}::{{ivar.name.stringify.camelcase.id}}FieldId{% if attrs.size > 0 %}, {{attrs.splat}}{% end %},
                name: {{ivar.name.stringify}} do
                __apply_before_render_{{ivar.name.id}}({{ivar.name.id}}).to_s
              end
            {% else %}
              input {{@type}}::{{ivar.name.stringify.camelcase.id}}FieldId{% if attrs.size > 0 %}, {{attrs.splat}}{% end %},
                type: {{control_type}},
                name: {{ivar.name.stringify}},
                value: __apply_before_render_{{ivar.name.id}}({{ivar.name.id}}).to_s
            {% end %}

            if field_errors = __error_messages_for(:{{ivar.name.id}})
              if field_errors.size > 0
                ul Crumble::FieldErrors do
                  field_errors.each do |error|
                    li do
                      error
                    end
                  end
                end
              end
            end
          end
        {% end %}
      {% end %}
    end
  end
end
