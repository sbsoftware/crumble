require "./spec_helper"
require "http/client/response"

module AssetFileRegistry
  def self.remove_for_spec(path)
    @@asset_files.delete(path)
  end
end

module RobotsSpec
  class PublicPage < Crumble::Page
    root_path "/public"

    template do
      "public"
    end
  end

  class AdminResource < Crumble::Resource
    root_path "/admin"

    def index
    end
  end
end

robots do
  user_agent "*" do
    disallow RobotsSpec::AdminResource
    allow RobotsSpec::PublicPage
    crawl_delay 3
  end

  user_agent "ExampleBot" do
    disallow "/private"
    allow "/private/preview"
  end

  sitemap "https://example.com/sitemap.xml"
end

private def dispatch_robots_request
  response_io = IO::Memory.new
  response = Crumble::Server::TestResponse.new(response_io)
  context = HTTP::Server::Context.new(Crumble::Server::TestRequest.new(resource: "/robots.txt"), response)

  Crumble::Server::RequestDispatcher.new.call(context)
  context.response.close

  response_io.rewind
  HTTP::Client::Response.from_io(response_io)
end

describe TxtFile do
  it "serves text/plain and keeps immutability configurable" do
    immutable = TxtFile.new("/robots-spec.txt", "hello")
    mutable = TxtFile.new("/robots-spec-mutable.txt", "hello", immutable: false)

    immutable.mime_type.should eq("text/plain")
    immutable.uri_path.should match(/\/robots-spec_[a-f0-9]{32}\.txt/)
    mutable.uri_path.should eq("/robots-spec-mutable.txt")
  end
end

describe Crumble::Robots do
  it "generates robots.txt content from typed directives" do
    Crumble::Robots.to_txt.should eq(<<-TXT + "\n")
    User-agent: *
    Disallow: /admin
    Allow: /public
    Crawl-delay: 3
    User-agent: ExampleBot
    Disallow: /private
    Allow: /private/preview
    Sitemap: https://example.com/sitemap.xml
    TXT
  end

  it "registers /robots.txt as a text asset" do
    response = dispatch_robots_request

    response.status_code.should eq(200)
    response.headers["Content-Type"].should eq("text/plain")
    response.headers["Cache-Control"].should eq("public, max-age=0, must-revalidate")
    response.body.should eq(Crumble::Robots.to_txt)
  end

  it "returns 404 for /robots.txt when no robots file is registered" do
    AssetFileRegistry.remove_for_spec("/robots.txt")
    response = dispatch_robots_request

    response.status_code.should eq(404)
    response.body.should eq("Not Found")
  ensure
    AssetFileRegistry.add(Crumble::Robots.uri_path, Crumble::Robots::File)
  end
end
