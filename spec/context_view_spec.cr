require "./spec_helper"

module Crumble::ContextViewSpec
  class MyContextView
    include Crumble::ContextView

    template do
      html do
        head do
          if window_title = ctx.handler.window_title
            title { window_title }
          end
        end
        body do
          main do
            if ctx.request.path == "/"
              h1 { "Welcome!" }
            else
              p { "Going further" }
            end
          end
        end
      end
    end
  end

  class MyResource < Crumble::Resource
    def window_title
      "Title!"
    end
  end

  describe MyContextView do
    it "should render the template depending on context" do
      rctx1 = Server::TestRequestContext.new(resource: "/")
      rctx2 = Server::TestRequestContext.new(resource: "/next")

      ctx1 = Server::HandlerContext.new(rctx1, MyResource.new(rctx1))
      ctx2 = Server::HandlerContext.new(rctx2, MyResource.new(rctx2))

      view1 = MyContextView.new(ctx: ctx1)
      view2 = MyContextView.new(ctx: ctx2)

      expected1 = <<-HTML.squish
      <html>
        <head>
          <title>Title!</title>
        </head>
        <body>
          <main>
            <h1>Welcome!</h1>
          </main>
        </body>
      </html>
      HTML

      expected2 = <<-HTML.squish
      <html>
        <head>
          <title>Title!</title>
        </head>
        <body>
          <main>
            <p>Going further</p>
          </main>
        </body>
      </html>
      HTML

      view1.to_html.should eq(expected1)
      view2.to_html.should eq(expected2)
    end
  end
end
