require "crumble"

# Load base application types first so files in nested folders can reference them.
require "./crumble/session"
require "./crumble/request_context"
require "./views/application_layout"
require "./pages/application_page"
require "./resources/application_resource"
require "./styles/application_style"

require "./crumble/**"
require "./models/**"
require "./views/**"
require "./pages/**"
require "./resources/**"
require "./styles/**"
