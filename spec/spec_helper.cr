require "spec"
require "../src/crumble"
require "./test_request_context"

class String
  def squish
    gsub(/\n\s*/, "")
  end
end
