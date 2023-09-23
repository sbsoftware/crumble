require "spec"
require "../src/util/*"
require "../src/orm/*"
require "../src/css/*"
require "../src/stimulus/stimulus_controller"
require "../src/resource/*"
require "../src/server/*"
require "./test_request_context"

class String
  def squish
    gsub(/\n\s*/, "")
  end
end
