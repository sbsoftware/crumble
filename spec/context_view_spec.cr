require "./spec_helper"

module Crumble::ContextViewSpec
  class MyContextView
    include Crumble::ContextView

    template do
      main do
        if ctx.request.path == "/"
          h1 { "Welcome!" }
        else
          p { "Going further" }
        end
      end
    end
  end

  describe MyContextView do
    it "should render the template depending on context" do
      ctx1 = Server::TestRequestContext.new(resource: "/")
      ctx2 = Server::TestRequestContext.new(resource: "/next")

      view1 = MyContextView.new(ctx: ctx1)
      view2 = MyContextView.new(ctx: ctx2)

      expected1 = <<-HTML.squish
      <main>
        <h1>Welcome!</h1>
      </main>
      HTML

      expected2 = <<-HTML.squish
      <main>
        <p>Going further</p>
      </main>
      HTML

      view1.to_html.should eq(expected1)
      view2.to_html.should eq(expected2)
    end
  end
end
