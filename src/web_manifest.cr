module Crumble
  abstract class WebManifest
    enum FormFactor
      Narrow
      Wide

      def to_s(io : IO)
        io << self.to_s.underscore
      end
    end

    record Icon, src : String, type : String, sizes : String? do
      include JSON::Serializable
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

    macro icon(asset_file, sizes = nil)
      def self.app_icons
        new_icon = Icon.new(src: {{asset_file}}.uri_path, type: {{asset_file}}.mime_type, sizes: {{sizes}})

        {% if @type.class.methods.map(&.name.stringify).includes?("app_icons") %}
          previous_def + {new_icon}
        {% else %}
          {new_icon}
        {% end %}
      end
    end

    macro screenshot(asset_file, sizes = nil, label = nil, form_factor = nil, platform = nil)
      def self.app_screenshots
        new_screenshot = Screenshot.new(src: {{asset_file}}.uri_path, type: {{asset_file}}.mime_type, sizes: {{sizes}}, label: {{label}}, form_factor: {{form_factor}}, platform: {{platform}})

        {% if @type.class.methods.map(&.name.stringify).includes?("app_screenshots") %}
          previous_def + {new_screenshot}
        {% else %}
          {new_screenshot}
        {% end %}
      end
    end

    def self.attributes
      {
        name: app_name,
        short_name: app_short_name,
        description: app_description,
        start_url: app_start_url,
        display: app_display,
        background_color: app_background_color,
        theme_color: app_theme_color,
        icons: app_icons,
        screenshots: app_screenshots
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
