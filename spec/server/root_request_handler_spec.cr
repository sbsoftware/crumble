require "../spec_helper"

module Crumble::Server::RootRequestHandlerPageSpec
  class HomePage < Crumble::Page
    view do
      template do
        html do
          body { "page handled" }
        end
      end
    end

    def self.root_path
      "/root-handler-page"
    end
  end

  class CapturingHandler
    @@called = false

    def self.handle(ctx)
      @@called = true
      ctx.response.print "fallback handler"
      true
    end

    def self.called?
      @@called
    end

    def self.reset
      @@called = false
    end
  end

  Crumble::Server::RootRequestHandler.add_request_handler ::Crumble::Server::RootRequestHandlerPageSpec::CapturingHandler
end

describe Crumble::Server::RootRequestHandler do
  it "routes pages before other request handlers" do
    handler = Crumble::Server::RootRequestHandler.new
    Crumble::Server::RootRequestHandlerPageSpec::CapturingHandler.reset

    response_io = IO::Memory.new
    request = Crumble::Server::TestRequest.new(resource: Crumble::Server::RootRequestHandlerPageSpec::HomePage.uri_path)
    response = Crumble::Server::TestResponse.new(response_io)
    context = HTTP::Server::Context.new(request, response)

    handler.call(context)
    context.response.flush

    response_io.rewind
    response_io.gets_to_end.should contain("page handled")
    Crumble::Server::RootRequestHandlerPageSpec::CapturingHandler.called?.should be_false
  end
end
