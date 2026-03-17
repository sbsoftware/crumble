require "./spec_helper"

module Crumble::PageSpec
  class ClassViewPage < Crumble::Page
    template do
      html do
        head do
          if title = window_title
            title { title }
          end
        end
        body do
          h1 { "Rendered from page template" }
        end
      end
    end

    def window_title
      "Page Title"
    end
  end

  class BlockPage < Crumble::Page
    template do
      html do
        body do
          p { "Inline page for #{ctx.request.path}" }
        end
      end
    end
  end

  class DirectTemplatePage < Crumble::Page
    path_param id

    template do
      html do
        body do
          h1 { "ID: #{id} (#{window_title})" }
        end
      end
    end

    def window_title
      "Direct Page"
    end
  end

  class PageLayout
    ToHtml.class_template do
      html do
        body { yield }
      end
    end
  end

  class LayoutPage < Crumble::Page
    template do
      div { "inside" }
    end

    layout PageLayout
  end

  class IdPage < Crumble::Page
    path_param id

    template do
      html do
        body do
          h1 { "ID: #{id}" }
        end
      end
    end
  end

  class NestedPage < Crumble::Page
    path_param id
    nested_path "details"

    template do
      html do
        body do
          h1 { "Nested ID: #{id}" }
        end
      end
    end
  end

  class TopLevelOnlyPage < Crumble::Page
    template do
      html do
        body do
          h1 { "Top level" }
        end
      end
    end
  end

  class CustomRootPathPage < Crumble::Page
    root_path "/custom"

    template do
      html do
        body do
          h1 { "Custom root path" }
        end
      end
    end
  end

  class MultiParamPage < Crumble::Page
    root_path "/multi"
    path_param account_id
    path_param slug, /[a-z0-9-]+/
    nested_path "edit"
    nested_path "details"

    template do
      html do
        body do
          h1 { "account_id=#{account_id} slug=#{slug}" }
        end
      end
    end
  end

  class SymbolNameParamPage < Crumble::Page
    root_path "/sym_param"
    path_param :id

    template do
      html do
        body do
          h1 { "Symbol ID: #{id}" }
        end
      end
    end
  end

  class StringNameParamPage < Crumble::Page
    root_path "/str_param"
    path_param "id"

    template do
      html do
        body do
          h1 { "String ID: #{id}" }
        end
      end
    end
  end

  class TemplateThenTemplatePage < Crumble::Page
    template do
      p { "template first" }
    end

    template do
      p { "template second" }
    end
  end
end

describe Crumble::Page do
  it "renders a page template directly" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::ClassViewPage.uri_path)
      Crumble::PageSpec::ClassViewPage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should contain("<h1>Rendered from page template</h1>")
    res.should contain("<title>Page Title</title>")
  end

  it "renders an inline page template" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::BlockPage.uri_path)
      Crumble::PageSpec::BlockPage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should contain("Inline page for #{Crumble::PageSpec::BlockPage.uri_path}")
  end

  it "does not generate a nested View class for template-defined pages" do
    {{Crumble::PageSpec::BlockPage.constants.map(&.id.stringify).includes?("View")}}.should be_false
  end

  it "renders template blocks directly on the page with page access" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::DirectTemplatePage.uri_path(id: 42))
      Crumble::PageSpec::DirectTemplatePage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should contain("ID: 42 (Direct Page)")
  end

  it "applies the configured layout" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::LayoutPage.uri_path)
      Crumble::PageSpec::LayoutPage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should contain("<html>")
    res.should contain("<body>")
    res.should contain("</body>")
    res.should contain("</html>")
    res.should contain("inside")
  end

  it "ignores non-GET requests" do
    ctx = Crumble::Server::TestRequestContext.new(resource: Crumble::PageSpec::ClassViewPage.uri_path, method: "POST")
    Crumble::PageSpec::ClassViewPage.handle(ctx).should eq(false)
  end

  it "renders the id when present in the path" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::IdPage.uri_path(id: 42))
      Crumble::PageSpec::IdPage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should contain("ID: 42")
  end

  it "builds uri_path including nested paths" do
    Crumble::PageSpec::NestedPage.uri_path(id: 7).should eq("#{Crumble::PageSpec::NestedPage._root_path}/7/details")
  end

  it "matches nested paths when handling requests" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::NestedPage.uri_path(id: 123))
      Crumble::PageSpec::NestedPage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should contain("Nested ID: 123")
  end

  it "by default only matches the derived root path" do
    Crumble::PageSpec::TopLevelOnlyPage.match(Crumble::PageSpec::TopLevelOnlyPage.uri_path).should be_truthy
    Crumble::PageSpec::TopLevelOnlyPage.match("#{Crumble::PageSpec::TopLevelOnlyPage.uri_path}/123").should be_falsey
  end

  it "allows overriding the derived root path via root_path macro" do
    Crumble::PageSpec::CustomRootPathPage._root_path.should eq("/custom")
    Crumble::PageSpec::CustomRootPathPage.match("/custom").should be_truthy
    Crumble::PageSpec::CustomRootPathPage.match("/custom/123").should be_falsey
  end

  it "supports multiple path_param and nested_path segments" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::MultiParamPage.uri_path(account_id: 123, slug: "abc-9"))
      Crumble::PageSpec::MultiParamPage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should contain("account_id=123 slug=abc-9")
    Crumble::PageSpec::MultiParamPage.match("/multi/123/abc_9/edit/details").should be_falsey
  end

  it "supports path_param names as Symbol or String literals" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::SymbolNameParamPage.uri_path(id: 9))
      Crumble::PageSpec::SymbolNameParamPage.handle(ctx).should eq(true)
      ctx.response.flush
    end
    res.should contain("Symbol ID: 9")

    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::StringNameParamPage.uri_path(id: 11))
      Crumble::PageSpec::StringNameParamPage.handle(ctx).should eq(true)
      ctx.response.flush
    end
    res.should contain("String ID: 11")
  end

  it "uses the last template when declared twice" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::TemplateThenTemplatePage.uri_path)
      Crumble::PageSpec::TemplateThenTemplatePage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should contain("template second")
    res.should_not contain("template first")
  end
end
