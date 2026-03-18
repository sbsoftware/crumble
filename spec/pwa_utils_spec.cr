require "./spec_helper"
require "http/client/response"

module Crumble::ServiceWorkerMacroSpec
  service_worker(scope: "/") do
    console.log("root-first")
  end

  service_worker(scope: "/admin") do
    console.log("admin-only")
  end

  service_worker(scope: "/") do
    console.log("root-second")
  end

  register_service_worker do
    console.log("root-third-via-alias")
  end

  class DummyLayout < ToHtml::Layout
    getter ctx : Crumble::Server::HandlerContext = test_handler_context

    def window_title
      "Service Worker Macro Spec"
    end

    def viewport_meta?
      false
    end
  end
end

private def dispatch_worker_request(path, headers = HTTP::Headers.new)
  handler = Crumble::Server::RequestDispatcher.new
  request = Crumble::Server::TestRequest.new(resource: path, headers: headers)

  response_io = IO::Memory.new
  response = Crumble::Server::TestResponse.new(response_io)
  context = HTTP::Server::Context.new(request, response)

  handler.call(context)
  context.response.close

  response_io.rewind
  HTTP::Client::Response.from_io(response_io)
end

private def count_substring(text : String, needle : String) : Int32
  text.split(needle).size - 1
end

describe "service_worker macro" do
  it "composes same-scope fragments in declaration order" do
    Crumble::ServiceWorkers::ScopedServiceWorkerRoot.uri_path.should eq("/service_worker.js")

    script = Crumble::ServiceWorkers::ScopedServiceWorkerRoot.to_js
    script.index("root-first").not_nil!.should be < script.index("root-second").not_nil!
    script.index("root-second").not_nil!.should be < script.index("root-third-via-alias").not_nil!
  end

  it "creates separate workers for different scopes" do
    Crumble::ServiceWorkers::ScopedServiceWorkerRoot.uri_path.should eq("/service_worker.js")
    Crumble::ServiceWorkers::ScopedServiceWorkerAdmin.uri_path.should eq("/service_worker__admin.js")
    Crumble::ServiceWorkers::ScopedServiceWorkerAdmin.to_js.should contain("admin-only")
  end

  it "emits one registration call per scope" do
    html = String.build do |io|
      Crumble::ServiceWorkerMacroSpec::DummyLayout.new(ctx: test_handler_context).to_html(io) { |_inner_io, _indent_level| }
    end

    count_substring(html, "navigator.serviceWorker.register(\"/service_worker.js\"").should eq(1)
    count_substring(html, "navigator.serviceWorker.register(\"/service_worker__admin.js\"").should eq(1)
    html.should contain(%(scope: "/"))
    html.should contain(%(scope: "/admin"))
  end

  it "serves service worker assets with non-immutable cache headers and keeps etag revalidation" do
    response = dispatch_worker_request(Crumble::ServiceWorkers::ScopedServiceWorkerRoot.uri_path)
    response.status_code.should eq(200)
    response.headers["Cache-Control"].should eq("public, max-age=0, must-revalidate")
    response.headers["ETag"].should_not be_empty
    response.body.should contain("root-first")

    headers = HTTP::Headers{"If-None-Match" => response.headers["ETag"]}
    not_modified = dispatch_worker_request(Crumble::ServiceWorkers::ScopedServiceWorkerRoot.uri_path, headers)
    not_modified.status_code.should eq(304)
    not_modified.body.should eq("")
  end
end
