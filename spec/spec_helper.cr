require "spec"
require "../src/crumble"
require "./test_request_context"

class String
  def squish
    gsub(/\n\s*/, "")
  end
end

# Needed for specs that call SessionDecorator#update! or Session#update!
class Crumble::Server::Session
  property foo : String?
  property blah : Int32?
end
