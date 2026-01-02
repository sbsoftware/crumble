# Crumble (Crystal web framework)

This project uses the **Crumble** framework for server-rendered Crystal applications.
These notes are written for coding agents working in this repo.

## Common commands

- Install dependencies: `shards install`
- Run dev server (watch mode): `./watch.sh`
- Build the app: `shards build`
- Run the app: `crystal run --error-trace src/<app>.cr -- --port 8080`
- Run tests: `crystal spec`
- Format code: `crystal tool format`

## Project layout (conventional)

- `src/<app>.cr` — main entrypoint (typically `Crumble::Server.start`)
- `src/pages/` — GET pages (`Crumble::Page`)
- `src/resources/` — REST-style handlers (`Crumble::Resource`)
- `src/views/` — layouts and reusable components (often `include Crumble::ContextView`)
- `src/crumble/` — request/session glue (`RequestContext`, `Session`, etc.)

## Crumble usage

- **Pages**: subclass `Crumble::Page`. Routes are derived from class names (e.g. `ArticlesPage` → `/articles`). Use `view do ... end` and put markup in `template do ... end`.
- **Resources**: subclass `Crumble::Resource` and implement `index/show/create/update/destroy` as needed. Use `render`, `redirect`, and `redirect_back`.
- **Views/components**: prefer IO-based rendering (`#to_html(io : IO)`) and Crumble’s typed DSLs instead of assembling HTML strings.

## Helper shards (use them directly)

Crumble builds on a few helper shards. Prefer their typed DSLs over stringly-typed HTML/CSS/JS:

- `to_html` — typed HTML DSL used for templates/layouts. Layouts are objects with `#to_html(io : IO)` that `yield` a page body.
- `css` — CSS builder. Prefer `style do ... end` with `css_class`/`css_id` for scoped selectors instead of raw CSS strings.
- `js` — JavaScript builder. Prefer `JS::Code` + `def_to_js` for small scripts (e.g. service worker / PWA helpers) instead of inline `<script>` strings.
- `opentelemetry-sdk` — tracing backend used by Crumble’s OpenTelemetry middleware. Configure exporters/providers in the app if traces are desired.

If you `require "to_html"`, `require "css"`, or `require "js"` in app code, consider listing them as direct dependencies in `shard.yml` (not only transitively via `crumble`) so version pinning stays explicit.
