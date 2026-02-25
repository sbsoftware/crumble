require "js"
require "to_html"
require "./web_manifest"

module Crumble
  macro finished
    {% registration_classes = @type.constants.select(&.stringify.starts_with?("ScopedServiceWorkerRegistration")).sort_by(&.stringify) %}
    {% unless registration_classes.empty? %}
      class ::ToHtml::Layout
        {% for registration_class in registration_classes %}
          append_to_head ::Crumble::{{registration_class.id}}
        {% end %}
      end
    {% end %}
  end
end

# Generates or extends a scope-specific service worker and includes one
# registration script per scope in `ToHtml::Layout`.
#
# Multiple calls for the same scope compose into one worker script. Fragments
# are merged in declaration order, so later blocks can override behavior from
# earlier blocks when they affect the same event flow.
#
# The generated service worker file path is deterministic and intentionally
# non-fingerprinted to keep updates revalidation-friendly.
macro service_worker(scope = "/", &blk)
  {% unless scope.is_a?(StringLiteral) %}
    {{scope.raise "`scope` must be a string literal"}}
  {% end %}

  {% scope_path = scope.id.stringify %}
  {% if scope_path.empty? %}
    {{scope.raise "`scope` must not be empty"}}
  {% end %}
  {% scope_path = "/#{scope_path}" unless scope_path.starts_with?("/") %}

  # Minimal deterministic mapping from scope to class/path identifiers.
  {% scope_key = scope_path.gsub(/[^A-Za-z0-9]/, "_").gsub(/^_+|_+$/, "") %}
  {% scope_key = "root" if scope_key.empty? %}
  {% worker_uri_path = scope_key == "root" ? "/service_worker.js" : "/service_worker__#{scope_key.id}.js" %}
  {% worker_class_name = "ScopedServiceWorker#{scope_key.id.camelcase}".id %}
  {% registration_class_name = "ScopedServiceWorkerRegistration#{scope_key.id.camelcase}".id %}

  class ::Crumble::{{worker_class_name}} < JS::File
    @@file : JavascriptFile? = nil

    def self.scope
      {{scope_path}}
    end

    def self.uri_path
      (@@file ||= JavascriptFile.new({{worker_uri_path}}, to_js, immutable: false)).uri_path
    end

    {% if blk %}
      js_fragment do
        {{blk.body}}
      end
    {% end %}
  end

  class ::Crumble::{{registration_class_name}} < JS::Code
    def_to_js do
      if navigator.serviceWorker
        navigator.serviceWorker.register(
          ::Crumble::{{worker_class_name}}.uri_path.to_js_ref,
          scope: ::Crumble::{{worker_class_name}}.scope.to_js_ref,
        )
      end
    end
  end
end

# Deprecated compatibility alias. Prefer `service_worker(scope: "/")`.
macro register_service_worker(&blk)
  {% if blk %}
    service_worker(scope: "/") do
      {{blk.body}}
    end
  {% else %}
    service_worker(scope: "/")
  {% end %}
end

# Allows to define a web manifest JSON file and automatically includes it in
# `ToHtml::Layout`. For each supported property, a macro is available to
# conveniently set its value:
#
# ```
# web_manifest do
#   name "My Application"
#   short_name "My App"
#   [...]
# end
# ```
#
# Supported properties are:
#   name, short_name, description, start_url, display, background_color,
#   theme_color
#
# Icons and Screenshots can be added via the `icon`/`screenshot` macros,
# respectively. These can be provided the nested properties as optional
# parameters. The first parameter must be a child class of `AssetFile`.
#
# ```
# web_manifest do
#   # Path must be provided relative to the project directory
#   Icon = PNGFile.register "icon.png", "assets/icon.png"
#
#   icon Icon, sizes: "192x192", purpose: :maskable
#
#   Screenshot = JPGFile.register "screenshot.jpg", "assets/screenshot.jpg"
#
#   screenshot Screenshot, sizes: "1280x1024", label: "A screenshot showing the app", form_factor: :wide, platform: "android"
# end
# ```
macro web_manifest(&blk)
  class WebManifest < Crumble::WebManifest
    {{blk.body}}
  end

  class ToHtml::Layout
    append_to_head WebManifest
  end
end
