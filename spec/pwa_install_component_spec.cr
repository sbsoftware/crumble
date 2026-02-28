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
    html.should contain("To install this app, tap Share, then Add to Home Screen.")
    style_asset.contents.should contain(".#{Crumble::PwaInstallComponent::InstallContainer} {")
    style_asset.contents.should contain("background: #f6edac;")
    style_asset.contents.should contain(".#{Crumble::PwaInstallComponent::InstallTrigger} {")
    style_asset.contents.should contain("background: #757575;")
    style_asset.contents.should contain(".#{Crumble::PwaInstallComponent::Hidden} {")
    style_asset.contents.should contain("display: none;")
  end

  it "captures deferred beforeinstallprompt and handles install outcomes on custom click" do
    script = Crumble::PwaInstallComponent::Script.to_js

    script.should contain("window.addEventListener(\"beforeinstallprompt\", (event) => {")
    script.should contain("event.preventDefault();")
    script.should contain("deferred_prompt = event;")
    script.should contain("button.addEventListener(\"click\", async function() {")
    script.should contain("deferred_prompt.prompt();")
    script.should contain("choice_result = await deferred_prompt.userChoice;")
    script.should contain("choice_result.outcome == \"accepted\"")
    script.should contain("choice_result.outcome == \"dismissed\"")
    script.should contain("deferred_prompt = undefined;")
    script.should contain("hidden_class = \"crumble--pwa-install-component--hidden\";")
    script.should contain("show_install_ui = () => {")
    script.should contain("root.classList.remove(hidden_class);")
  end

  it "keeps the control mobile-only, hides when standalone, and shows iOS Safari fallback panel" do
    script = Crumble::PwaInstallComponent::Script.to_js

    script.should contain("is_mobile = mobile_media.matches || is_mobile_agent;")
    script.should contain("(window.matchMedia(\"(display-mode: standalone)\")).matches || (navigator.standalone == true)")
    script.should contain("if ((is_mobile == false) || is_standalone) {")
    script.should contain("if (is_ios_safari) {")
    script.should contain("close_panel();")
    script.should contain("open_panel();")
    script.should contain("panel.classList.add(hidden_class);")
    script.should contain("panel.classList.remove(hidden_class);")
    script.should contain("root.classList.add(hidden_class);")
    script.should contain("panel.addEventListener(\"click\", (event) => {")
    script.should contain("if (event.target == panel) {")
    script.should contain("window.addEventListener(\"appinstalled\", () => {")
  end
end
