require "./spec_helper"

module Crumble::PageSpec
  class ViewFromClass
    include Crumble::ContextView

    template do
      html do
        head do
          if title = ctx.handler.window_title
            title { title }
          end
        end
        body do
          h1 { "Rendered from class view" }
        end
      end
    end
  end

  class ClassViewPage < Crumble::Page
    view ViewFromClass

    def window_title
      "Page Title"
    end
  end

  class BlockPage < Crumble::Page
    view do
      template do
        html do
          body do
            p { "Inline page for #{ctx.request.path}" }
          end
        end
      end
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
    view do
      template do
        div { "inside" }
      end
    end

    layout PageLayout
  end

  class IdPage < Crumble::Page
    path_param id

    view do
      template do
        html do
          body do
            h1 { "ID: #{ctx.handler.as(Crumble::PageSpec::IdPage).id}" }
          end
        end
      end
    end
  end

  class NestedPage < Crumble::Page
    path_param id
    nested_path "details"

    view do
      template do
        html do
          body do
            h1 { "Nested ID: #{ctx.handler.as(Crumble::PageSpec::NestedPage).id}" }
          end
        end
      end
    end
  end

  class TopLevelOnlyPage < Crumble::Page
    view do
      template do
        html do
          body do
            h1 { "Top level" }
          end
        end
      end
    end
  end

  class CustomRootPathPage < Crumble::Page
    root_path "/custom"

    view do
      template do
        html do
          body do
            h1 { "Custom root path" }
          end
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

    view do
      template do
        html do
          body do
            page = ctx.handler.as(Crumble::PageSpec::MultiParamPage)
            h1 { "account_id=#{page.account_id} slug=#{page.slug}" }
          end
        end
      end
    end
  end

  class SymbolNameParamPage < Crumble::Page
    root_path "/sym_param"
    path_param :id

    view do
      template do
        html do
          body do
            h1 { "Symbol ID: #{ctx.handler.as(Crumble::PageSpec::SymbolNameParamPage).id}" }
          end
        end
      end
    end
  end

  class StringNameParamPage < Crumble::Page
    root_path "/str_param"
    path_param "id"

    view do
      template do
        html do
          body do
            h1 { "String ID: #{ctx.handler.as(Crumble::PageSpec::StringNameParamPage).id}" }
          end
        end
      end
    end
  end
end

describe Crumble::Page do
  it "renders a ContextView class via the view macro" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::ClassViewPage.uri_path)
      Crumble::PageSpec::ClassViewPage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should contain("<h1>Rendered from class view</h1>")
    res.should contain("<title>Page Title</title>")
  end

  it "renders an inline view block" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::BlockPage.uri_path)
      Crumble::PageSpec::BlockPage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should contain("Inline page for #{Crumble::PageSpec::BlockPage.uri_path}")
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
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::IdPage.uri_path(42))
      Crumble::PageSpec::IdPage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should contain("ID: 42")
  end

  it "builds uri_path including nested paths" do
    Crumble::PageSpec::NestedPage.uri_path(7).should eq("#{Crumble::PageSpec::NestedPage.root_path}/7#{Crumble::PageSpec::NestedPage.nested_path}")
  end

  it "matches nested paths when handling requests" do
    res = String.build do |io|
      path = "#{Crumble::PageSpec::NestedPage.root_path}/123#{Crumble::PageSpec::NestedPage.nested_path}"
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: path)
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
    Crumble::PageSpec::CustomRootPathPage.root_path.should eq("/custom")
    Crumble::PageSpec::CustomRootPathPage.match("/custom").should be_truthy
    Crumble::PageSpec::CustomRootPathPage.match("/custom/123").should be_falsey
  end

  it "supports multiple path_param and nested_path segments" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: "/multi/123/abc-9/edit/details")
      Crumble::PageSpec::MultiParamPage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should contain("account_id=123 slug=abc-9")
    Crumble::PageSpec::MultiParamPage.match("/multi/123/abc_9/edit/details").should be_falsey
  end

  it "supports path_param names as Symbol or String literals" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::SymbolNameParamPage.uri_path(9))
      Crumble::PageSpec::SymbolNameParamPage.handle(ctx).should eq(true)
      ctx.response.flush
    end
    res.should contain("Symbol ID: 9")

    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::PageSpec::StringNameParamPage.uri_path(11))
      Crumble::PageSpec::StringNameParamPage.handle(ctx).should eq(true)
      ctx.response.flush
    end
    res.should contain("String ID: 11")
  end
end
