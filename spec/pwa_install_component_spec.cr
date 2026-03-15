require "./spec_helper"

module Crumble::PwaInstallComponentSpec
  class LayoutWithInstall < ToHtml::Layout
    ToHtml.instance_template do
      super do
        Crumble::PwaInstallComponent.new(ctx: ctx).to_html
      end
    end

    def window_title
      "Pwa Install Component Spec"
    end
  end
end

describe Crumble::PwaInstallComponent do
  it "renders as a drop-in layout component via #to_html" do
    html = Crumble::PwaInstallComponentSpec::LayoutWithInstall.new(ctx: test_handler_context).to_html
    style_asset = AssetFileRegistry.query(Crumble::PwaInstallComponent::Style.uri_path).not_nil!

    html.should contain(%(<link rel="stylesheet" href="#{Crumble::PwaInstallComponent::Style.uri_path}">))
    html.should contain(%(<div class="#{Crumble::PwaInstallComponent::InstallContainer} #{Crumble::PwaInstallComponent::Hidden}">))
    html.should contain(%(<button class="#{Crumble::PwaInstallComponent::InstallTrigger}" type="button" aria-haspopup="dialog">Install app</button>))
    html.should contain(%(<div class="#{Crumble::PwaInstallComponent::InstallPanel} #{Crumble::PwaInstallComponent::Hidden}">))
    html.should contain(%(<button class="#{Crumble::PwaInstallComponent::InstallPanelClose}" type="button" aria-label="Close install instructions">Close</button>))
    html.should contain("To install this app, tap Share in the menu, then Add to Home Screen.")
    style_asset.contents.should contain(".#{Crumble::PwaInstallComponent::InstallContainer} {")
    style_asset.contents.should contain("background: #f6edac;")
    style_asset.contents.should contain(".#{Crumble::PwaInstallComponent::InstallTrigger} {")
    style_asset.contents.should contain("margin: 0 auto;")
    style_asset.contents.should contain("background: #757575;")
    style_asset.contents.should contain("padding: 1rem 0.75rem 4rem;")
    style_asset.contents.should contain("margin-left: auto;")
    style_asset.contents.should contain(".#{Crumble::PwaInstallComponent::Hidden} {")
    style_asset.contents.should contain("display: none;")
  end
end
