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

    html.should contain(%(<div id="crumble-pwa-install" hidden>))
    html.should contain(%(<button id="crumble-pwa-install-trigger" type="button" aria-haspopup="dialog" aria-controls="crumble-pwa-install-panel">Install app</button>))
    html.should contain(%(<div id="crumble-pwa-install-panel" hidden>))
    html.should contain(%(<button id="crumble-pwa-install-panel-close" type="button" aria-label="Close install instructions">Close</button>))
    html.should contain("To install this app, tap Share, then Add to Home Screen.")
    html.should contain("#crumble-pwa-install {")
    html.should contain("background: #f6edac;")
    html.should contain("#crumble-pwa-install-trigger {")
    html.should contain("background: #757575;")
  end

  it "captures deferred beforeinstallprompt and handles install outcomes on custom click" do
    script = Crumble::PwaInstallComponent::Script.to_js

    script.should contain("window.addEventListener(\"beforeinstallprompt\", event => {")
    script.should contain("event.preventDefault();")
    script.should contain("deferredPrompt = event;")
    script.should contain("button.addEventListener(\"click\", async () => {")
    script.should contain("deferredPrompt.prompt();")
    script.should contain("const choiceResult = await deferredPrompt.userChoice;")
    script.should contain("choiceResult.outcome === \"accepted\"")
    script.should contain("choiceResult.outcome === \"dismissed\"")
    script.should contain("deferredPrompt = null;")
  end

  it "keeps the control mobile-only, hides when standalone, and shows iOS Safari fallback panel" do
    script = Crumble::PwaInstallComponent::Script.to_js

    script.should contain("const isMobile = mobileMedia.matches || isMobileAgent;")
    script.should contain("window.matchMedia(\"(display-mode: standalone)\").matches || window.navigator.standalone === true")
    script.should contain("if (!isMobile || isStandalone()) {")
    script.should contain("if (isIosSafari) {")
    script.should contain("closePanel();")
    script.should contain("openPanel();")
    script.should contain("panel.addEventListener(\"click\", event => {")
    script.should contain("if (event.target === panel) closePanel();")
    script.should contain("window.addEventListener(\"appinstalled\", () => {")
  end
end
