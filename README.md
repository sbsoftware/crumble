# Crumble

A Crystal web framework for server-rendered applications. Crumble wires together typed HTML views, REST-style resources, session handling, and a fingerprinted asset pipeline so you can build full-stack apps in a single binary without any front-end build step.
Build your views completely in Crystal with typed DSLs for HTML, CSS and even JavaScript! Finally define your styles right next to your markup to never lose context, but with real CSS instead of clunky frameworks.

## Installation

1. Add Crumble to your `shard.yml` dependencies:

```yaml
dependencies:
  crumble:
    github: sbsoftware/crumble
```

2. Install shards and build the CLI:

```sh
shards install
```

## Usage

The `bin/crumble` executable generates a starter layout. A minimal server looks like:

```crystal
require "crumble"
require "./pages/**"
require "./resources/**"

Crumble::Server.start
```

### Pages

`Crumble::Page` handles GET requests and automatically derives its route from the class name (`ArticlesPage` → `/articles`). Declare a view with the `view` macro; Crumble will render it into the response and wrap it in an optional layout.

```crystal
require "css"

class ArticlesPage < Crumble::Page
  layout ToHtml::Layout

  before do
    # Return `true` to continue, `false` for 400, or an Int32 HTTP status code.
    ctx.request.headers["X-Auth"]? == "1" ? true : 401
  end

  view do
    css_class ArticleListBox

    # HTML
    template do
      div ArticleListBox do
        h1 { "Articles" }
        ul do
          li { "Statically typed HTML, no strings attached." }
        end
      end
    end

    # Scoped styles
    style do
      rule ArticleListBox do
        max_width 720.px
        margin_top 32.px
        margin_left 24.px
        margin_right 24.px
        font_family "Inter, system-ui, sans-serif"
        line_height 1.5

        rule "h1" do
          margin_bottom 12.px
        end

        rule "li" do
          margin_bottom 6.px
        end
      end
    end
  end
end
```

- Pass a class to `view(SomeView)` if you prefer a reusable component.
- `layout SomeLayout` can reference an existing layout class, which is just something with a `#to_html(io : IO)` method that yields; when omitted, the view renders bare.
- Use `before { ... }` to short-circuit with `false` (400) or an `Int32` status code.

#### Path matching

Pages can declare URL parameters and nested segments with path-matching macros:

```crystal
class AccountPostDetailsPage < Crumble::Page
  root_path "/accounts"
  path_param account_id
  path_param slug, /[a-z0-9-]+/
  nested_path "posts"
  nested_path "details"

  view do
    template do
      page = ctx.handler.as(AccountPostDetailsPage)
      p { "account_id=#{page.account_id} slug=#{page.slug}" }
    end
  end
end

AccountPostDetailsPage.uri_path(account_id: 123, slug: "hello-world")
# => /accounts/123/hello-world/posts/details
```

### Resources

`Crumble::Resource` gives you RESTful handlers with sensible defaults for `index`, `show`, `create`, `update`, and `destroy`. Routing follows the class name (`CommentsResource` → `/comments`); nested paths are supported one level deep via `self.nested_path`.

```crystal
require "css"

class CommentsResource < Crumble::Resource
  layout ToHtml::Layout

  before(:create) { true }

  def index
    render CommentsView
  end

  def create
    # mutate state, then redirect
    redirect uri_path
  end
end

class CommentsView
  include Crumble::ContextView

  css_class CommentsBox

  # HTML
  template do
    div CommentsBox do
      h1 { "Comments" }
      p { "Hello from a Resource-backed view." }
    end
  end

  # Scoped styles
  style do
    rule CommentsBox do
      background_color "#f8f9fb"
      padding 16.px
      border_radius 8.px
      box_shadow "0 4px 24px rgba(0, 0, 0, 0.06)"

      rule "h1" do
        margin_bottom 8.px
        font_size 22.px
      end

      rule "p" do
        margin_top 0.px
        color "#334155"
      end
    end
  end
end
```

- `render SomeView` wraps the view in the configured layout and sets `Content-Type` to HTML.
- `redirect` and `redirect_back` set a `303 See Other` by default.
- Add `before` filters to short-circuit with `false` (400) or an `Int32` status code.

### Forms

`Crumble::Form` lets you define typed form fields, render them as inputs, and parse incoming values from URL-encoded form bodies.

```crystal
class ProfileForm < Crumble::Form
  field name : String
  field bio : String?, label: nil
  field slug : String do
    before_render do |value|
      value.upcase
    end

    after_submit do |value|
      value.strip
    end
  end
end

form = ProfileForm.from_www_form(ctx, ctx.request.body.try(&.gets_to_end) || "")
form.valid? # => false if any non-nilable field is nil
form.values # => {name: "...", bio: nil, slug: "..."}
```

- Each `field` supports `type:` and `label:` options for rendering.
- Override `default_label_caption(field)` in your form to customize default label text.
- `before_render` transforms a field value right before rendering its `<input>`.
- `after_submit` transforms a field value whenever it is assigned (including `from_www_form`).

### Server & Routing

- `Crumble::Server.start` boots an `HTTP::Server` with logging and optional OpenTelemetry tracing (`CRUMBLE_HOST` + `--port` flag control the bind address).
- Sessions are pluggable: override `RequestContext.init_session_store` to switch from the in-memory default to the file-backed store (e.g. `FileSessionStore.new("/tmp/sessions")`) or your own implementation.

### Assets

Use `AssetFile` to serve fingerprinted static files with cache-busting ETags. Subclasses like `PngFile` set MIME types for you; just register your files, assigning them to a constant/variable, and they'll be served when used in your markup!

```Crystal
MyPicture = PngFile.register "assets/my_picture.png"

class HomePage < Crumble::Page
  view do
    template do
      div do
        img src: MyPicture.uri_path
      end
    end
  end
end
```

## Powered By

- **[to_html.cr](https://github.com/sbsoftware/to_html.cr)** — a typed HTML DSL that emits valid markup at compile time. Crumble extends it with `Crumble::ContextView`, giving views access to the request context (`ctx`) and adding a `template` macro for concise component definitions.
- **[css.cr](https://github.com/sbsoftware/css.cr)** — a Crystal CSS builder. Use the `style` macro to generate stylesheet assets that are automatically appended to the base layout of the site. Classes defined via `css_class`/`css_id` can be directly used as arguments to CSS rules (`rule MyClass do [...] end`) as well as HTML tags (`div MyClass do [...] end`).

## Contributing

1. Fork the repo and create your branch from `main`.
2. Add or update specs alongside code changes.
3. Open a pull request.

## Contributors

- [Stefan Bilharz](https://github.com/sbsoftware) (creator & maintainer)

## License

MIT
