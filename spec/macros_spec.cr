require "./spec_helper"

module Crumble::StyleMacroSpec
  style do
    rule body do
      font_size 14.px
    end
  end

  module Nested
    style CustomStyle do
      rule div do
        color "red"
      end
    end
  end

  class DummyLayout < ToHtml::Layout
    getter ctx : Crumble::Server::HandlerContext = test_handler_context

    def window_title
      "Test"
    end

    def viewport_meta?
      false
    end
  end
end

describe "style macro" do
  it "creates a stylesheet class and stores CSS" do
    asset_file = AssetFileRegistry.query(Crumble::StyleMacroSpec::Style.uri_path).not_nil!
    asset_file.contents.should match(/body \{\n  font-size: 14px;\n\}/)
  end

  it "appends the stylesheet to layouts" do
    layout = Crumble::StyleMacroSpec::DummyLayout.new(ctx: test_handler_context)
    layout.head_children.should contain(Crumble::StyleMacroSpec::Style)
  end

  it "uses the namespace when inside another type" do
    layout = Crumble::StyleMacroSpec::DummyLayout.new(ctx: test_handler_context)
    layout.head_children.should contain(Crumble::StyleMacroSpec::Nested::CustomStyle)
  end
end
