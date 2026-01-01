module Crumble
  abstract class WebManifest
    enum FormFactor
      Narrow
      Wide

      def to_s(io : IO)
        io << self.to_s.underscore
      end
    end

    enum IconPurpose
      Any
      Maskable
      Monochrome

      def to_s(io : IO)
        io << self.to_s.underscore
      end
    end

    module IconPurposeListConverter
      def self.to_json(value : Array(IconPurpose), json : JSON::Builder)
        json.string(value.map(&.to_s.underscore).join(" "))
      end

      def self.from_json(pull : JSON::PullParser) : Array(IconPurpose)?
        return nil if pull.kind.null?

        value = pull.read_string
        value.split(' ', remove_empty: true).map { |token| IconPurpose.parse(token.camelcase) }
      end
    end

    struct Icon
      include JSON::Serializable

      getter src : String
      getter type : String
      getter sizes : String?

      @[JSON::Field(converter: ::Crumble::WebManifest::IconPurposeListConverter)]
      getter purpose : Array(IconPurpose)?

      def initialize(
        @src : String,
        @type : String,
        @sizes : String? = nil,
        @purpose : Array(IconPurpose)? = nil,
      )
      end
    end

    record Screenshot, src : String, type : String, sizes : String?, label : String?, form_factor : FormFactor?, platform : String? do
      include JSON::Serializable
    end

    module ClassMethods
      abstract def app_name
      abstract def app_short_name
      abstract def app_icons
    end

    macro inherited
      extend ClassMethods

      File = WebManifestFile.new(self.to_json)

      def self.uri_path
        File.uri_path
      end
    end

    macro name(new_name)
      def self.app_name
        {{new_name}}
      end
    end

    macro short_name(new_short_name)
      def self.app_short_name
        {{new_short_name}}
      end
    end

    macro description(new_description)
      def self.app_description
        {{new_description}}
      end
    end

    macro start_url(new_start_url)
      def self.app_start_url
        {{new_start_url}}
      end
    end

    macro display(new_display)
      def self.app_display
        {{new_display}}
      end
    end

    macro background_color(new_background_color)
      def self.app_background_color
        {{new_background_color}}
      end
    end

    macro theme_color(new_theme_color)
      def self.app_theme_color
        {{new_theme_color}}
      end
    end

    # Helper for the `icon(..., purpose: ...)` macro:
    # ensures we only accept real `IconPurpose` values in the runtime record while
    # still allowing the nicer `:maskable` symbol syntax at the macro callsite.
    protected def self.icon_purpose(purpose : IconPurpose) : IconPurpose
      purpose
    end

    macro icon(asset_file, sizes = nil, purpose = nil)
      def self.app_icons
        {% if purpose.is_a?(NilLiteral) %}
          icon_purpose = nil
        {% elsif purpose.is_a?(ArrayLiteral) || purpose.is_a?(TupleLiteral) %}
          # Map each literal at compile-time so `{:monochrome, :maskable}` becomes
          # `Array(IconPurpose)` (Crystal won't infer enum values inside enumerables).
          icon_purpose = [
            {% for p in purpose %}
              self.icon_purpose({{p}}),
            {% end %}
          ]
        {% else %}
          icon_purpose = [self.icon_purpose({{purpose}})]
        {% end %}

        new_icon = ::Crumble::WebManifest::Icon.new(
          src: {{asset_file}}.uri_path,
          type: {{asset_file}}.mime_type,
          sizes: {{sizes}},
          purpose: icon_purpose,
        )

        {% if @type.class.methods.map(&.name.stringify).includes?("app_icons") %}
          previous_def + {new_icon}
        {% else %}
          {new_icon}
        {% end %}
      end
    end

    macro screenshot(asset_file, sizes = nil, label = nil, form_factor = nil, platform = nil)
      def self.app_screenshots
        new_screenshot = ::Crumble::WebManifest::Screenshot.new(src: {{asset_file}}.uri_path, type: {{asset_file}}.mime_type, sizes: {{sizes}}, label: {{label}}, form_factor: {{form_factor}}, platform: {{platform}})

        {% if @type.class.methods.map(&.name.stringify).includes?("app_screenshots") %}
          previous_def + {new_screenshot}
        {% else %}
          {new_screenshot}
        {% end %}
      end
    end

    def self.attributes
      {
        name:             app_name,
        short_name:       app_short_name,
        description:      app_description,
        start_url:        app_start_url,
        display:          app_display,
        background_color: app_background_color,
        theme_color:      app_theme_color,
        icons:            app_icons,
        screenshots:      app_screenshots,
      }
    end

    def self.to_json
      attributes.to_h.compact.to_json
    end

    ToHtml.class_tag_attrs do
      link do
        rel = "manifest"
        href = uri_path
      end
    end

    ToHtml.class_template do
      link self
    end

    # Default values

    def self.app_description
      nil
    end

    def self.app_start_url
      "/"
    end

    def self.app_display
      "standalone"
    end

    def self.app_background_color
      nil
    end

    def self.app_theme_color
      nil
    end

    def self.app_screenshots
      Tuple.new
    end
  end
end
