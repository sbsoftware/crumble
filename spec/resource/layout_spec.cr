require "../spec_helper"

module Crumble::Resource::LayoutSpec
  class MyLayout
    def self.page_title
      "MySite"
    end

    ToHtml.class_template do
      header do
        page_title
      end
      main do
        yield
      end
    end
  end

  class MyView
    ToHtml.class_template do
      div { "content!" }
    end
  end

  class MyResource < Resource
    layout MyLayout do
      def self.page_title
        "MyResource - #{super}"
      end
    end

    def index
      render MyView
    end
  end

  describe "MyResource.handle" do
    it "should print the correct HTML to the HTTP response" do
      res = String.build do |io|
        ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: MyResource.uri_path)
        MyResource.handle(ctx)
        ctx.response.flush
      end

      expected = <<-HTML.squish
      <header>MyResource - MySite</header>
      <main>
        <div>content!</div>
      </main>
      HTML

      res.should contain(expected)
    end
  end
end
