require "../spec_helper"
require "http/client/response"

class Crumble::Server::RequestContext
  def self.reset_session_store_for_spec
    @@session_store = nil
  end
end

module Crumble::Server::RequestDispatcherPageSpec
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
      return false unless ctx.request.path == HomePage.uri_path
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

  Crumble::Server::RequestDispatcher.add_request_handler ::Crumble::Server::RequestDispatcherPageSpec::CapturingHandler
end

module Crumble::Server::RequestDispatcherResourceSpec
  class WidgetResource < Crumble::Resource
    def self.root_path
      "/root-handler-resource"
    end

    def index
      ctx.response.print "resource index"
    end

    def show
      ctx.response.print "resource show #{id}"
    end

    def create
      ctx.response.print "resource create"
    end

    def update
      ctx.response.print "resource update #{id}"
    end
  end

  class SessionResource < Crumble::Resource
    def self.root_path
      "/root-handler-session"
    end

    def index
      current = ctx.session.blah || 0
      ctx.session.update!(blah: current + 1)
      ctx.response.print "session blah=#{ctx.session.blah}"
    end
  end
end

private def dispatch_request(handler, request)
  response_io = IO::Memory.new
  response = Crumble::Server::TestResponse.new(response_io)
  context = HTTP::Server::Context.new(request, response)

  handler.call(context)
  context.response.close

  response_io.rewind
  HTTP::Client::Response.from_io(response_io)
end

describe Crumble::Server::RequestDispatcher do
  it "routes pages before other request handlers" do
    handler = Crumble::Server::RequestDispatcher.new
    Crumble::Server::RequestDispatcherPageSpec::CapturingHandler.reset

    request = Crumble::Server::TestRequest.new(resource: Crumble::Server::RequestDispatcherPageSpec::HomePage.uri_path)
    response = dispatch_request(handler, request)
    response.body.should contain("page handled")
    Crumble::Server::RequestDispatcherPageSpec::CapturingHandler.called?.should be_false
  end

  it "handles page GET requests" do
    handler = Crumble::Server::RequestDispatcher.new

    request = Crumble::Server::TestRequest.new(
      method: "GET",
      resource: Crumble::Server::RequestDispatcherPageSpec::HomePage.uri_path,
    )
    response = dispatch_request(handler, request)

    response.headers["Content-Type"].should eq("text/html")
    response.body.should contain("page handled")
  end

  it "falls back to other request handlers for page POST requests" do
    handler = Crumble::Server::RequestDispatcher.new
    Crumble::Server::RequestDispatcherPageSpec::CapturingHandler.reset

    request = Crumble::Server::TestRequest.new(
      method: "POST",
      resource: Crumble::Server::RequestDispatcherPageSpec::HomePage.uri_path,
    )
    response = dispatch_request(handler, request)

    response.body.should eq("fallback handler")
    Crumble::Server::RequestDispatcherPageSpec::CapturingHandler.called?.should be_true
  end

  it "delivers asset files" do
    handler = Crumble::Server::RequestDispatcher.new

    asset = CssFile.new("/root-handler-asset.css", "body{color:red}")
    request = Crumble::Server::TestRequest.new(resource: asset.uri_path)
    response = dispatch_request(handler, request)

    response.status_code.should eq(200)
    response.headers["Content-Type"].should eq("text/css")
    response.headers["ETag"].should eq(asset.etag)
    response.headers["Cache-Control"].should contain("immutable")
    response.body.should eq("body{color:red}")
  end

  it "returns 304 for asset files when ETag matches" do
    handler = Crumble::Server::RequestDispatcher.new

    asset = CssFile.new("/root-handler-asset-304.css", "body{color:blue}")
    headers = HTTP::Headers{"If-None-Match" => asset.etag}
    request = Crumble::Server::TestRequest.new(resource: asset.uri_path, headers: headers)
    response = dispatch_request(handler, request)

    response.status_code.should eq(304)
    response.body.should eq("")
  end

  it "handles resource GET requests" do
    handler = Crumble::Server::RequestDispatcher.new

    request = Crumble::Server::TestRequest.new(resource: Crumble::Server::RequestDispatcherResourceSpec::WidgetResource.uri_path)
    response = dispatch_request(handler, request)
    response.body.should eq("resource index")

    show_request = Crumble::Server::TestRequest.new(resource: Crumble::Server::RequestDispatcherResourceSpec::WidgetResource.uri_path(123))
    show_response = dispatch_request(handler, show_request)
    show_response.body.should eq("resource show 123")
  end

  it "handles resource POST requests" do
    handler = Crumble::Server::RequestDispatcher.new

    create_request = Crumble::Server::TestRequest.new(
      method: "POST",
      resource: Crumble::Server::RequestDispatcherResourceSpec::WidgetResource.uri_path,
    )
    create_response = dispatch_request(handler, create_request)
    create_response.body.should eq("resource create")

    update_request = Crumble::Server::TestRequest.new(
      method: "POST",
      resource: Crumble::Server::RequestDispatcherResourceSpec::WidgetResource.uri_path(123),
    )
    update_response = dispatch_request(handler, update_request)
    update_response.body.should eq("resource update 123")
  end

  it "retains session over multiple requests" do
    Crumble::Server::RequestContext.reset_session_store_for_spec
    handler = Crumble::Server::RequestDispatcher.new

    first_request = Crumble::Server::TestRequest.new(resource: Crumble::Server::RequestDispatcherResourceSpec::SessionResource.uri_path)
    first_response = dispatch_request(handler, first_request)

    cookie = first_response.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME]
    cookie.value.should_not be_empty
    first_response.body.should eq("session blah=1")

    second_request = Crumble::Server::TestRequest.new(resource: Crumble::Server::RequestDispatcherResourceSpec::SessionResource.uri_path)
    second_request.cookies[Crumble::Server::RequestContext::SESSION_COOKIE_NAME] = cookie.value
    second_response = dispatch_request(handler, second_request)

    second_response.headers.has_key?("Set-Cookie").should be_false
    second_response.body.should eq("session blah=2")
  end
end
