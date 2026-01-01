require "js"
require "to_html"
require "./web_manifest"

# Generates a service worker containing the JS code provided in the given block
# and automatically registers it within `ToHtml::Layout`.
#
# If no block or an empty block is provided, an empty service worker will be
# registered. This can still be useful for browsers to recognize the website as
# a PWA.
#
# Should only be called once per project. If you need more service workers,
# this macro won't serve you well.
macro register_service_worker(&blk)
  class ServiceWorker < JS::Code
    File = JavascriptFile.new("/service_worker.js", self.to_js)

    def self.uri_path
      File.uri_path
    end

    def_to_js do
      {% if blk %}
        {{blk.body}}
      {% end %}
    end
  end

  class ServiceWorkerRegistration < JS::Code
    def_to_js do
      if navigator.serviceWorker
        navigator.serviceWorker.register(ServiceWorker.uri_path.to_js_ref)
      end
    end
  end

  class ToHtml::Layout
    append_to_head ServiceWorkerRegistration
  end
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
