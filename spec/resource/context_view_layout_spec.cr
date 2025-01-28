require "../spec_helper"

module Crumble::Resource::ContextViewLayoutSpec
  class MyLayout
    include Crumble::ContextView

    template do
      html do
        body do
          header do
            "You are at #{ctx.request.path}"
          end
          yield
        end
      end
    end
  end

  class MyView
    include Crumble::ContextView

    template do
      div do
        "Your IP is #{ctx.request.remote_address}"
      end
    end
  end

  class MyResource < Resource
    layout MyLayout

    def index
      render MyView
    end
  end

  describe "MyResource.handle" do
    it "should print the correct HTML to the HTTP response" do
      res = String.build do |io|
        ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: MyResource.uri_path, remote_address: "252.35.18.5")
        MyResource.handle(ctx)
        ctx.response.flush

        ctx.response.headers["Content-Type"].should eq("text/html")
      end

      expected = <<-HTML.squish
      <html>
        <body>
          <header>You are at /crumble/resource/context_view_layout_spec/my</header>
          <div>Your IP is 252.35.18.5:80</div>
        </body>
      </html>
      HTML

      res.should contain(expected)
    end
  end
end
