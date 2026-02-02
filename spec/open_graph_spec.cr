require "./spec_helper"

module Crumble::OpenGraphSpec
  class OpenGraphPage < Crumble::Page
    view do
      template do
        div { "Open Graph" }
      end
    end

    layout ToHtml::Layout

    def og_title : String?
      "Invite title"
    end

    def og_description : String?
      "Short description"
    end

    def og_image : String?
      "https://example.com/preview.png"
    end

    def og_url : String?
      "https://example.com/invite"
    end

    def og_type : String?
      "website"
    end

    def og_site_name : String?
      "Example"
    end
  end

  class DefaultOpenGraphPage < Crumble::Page
    view do
      template do
        div { "Default" }
      end
    end

    layout ToHtml::Layout
  end
end

describe "OpenGraph meta tags" do
  it "renders provided OpenGraph tags in the layout head" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::OpenGraphSpec::OpenGraphPage.uri_path)
      Crumble::OpenGraphSpec::OpenGraphPage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should contain("<meta property=\"og:title\" content=\"Invite title\">")
    res.should contain("<meta property=\"og:description\" content=\"Short description\">")
    res.should contain("<meta property=\"og:image\" content=\"https://example.com/preview.png\">")
    res.should contain("<meta property=\"og:url\" content=\"https://example.com/invite\">")
    res.should contain("<meta property=\"og:type\" content=\"website\">")
    res.should contain("<meta property=\"og:site_name\" content=\"Example\">")
  end

  it "omits OpenGraph tags when none are provided" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::OpenGraphSpec::DefaultOpenGraphPage.uri_path)
      Crumble::OpenGraphSpec::DefaultOpenGraphPage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should_not contain("property=\"og:")
  end
end
