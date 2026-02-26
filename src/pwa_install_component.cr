require "js"
require "to_html"

module Crumble
  class PwaInstallComponent
    include Crumble::ContextView

    class Script < JS::Code
      def_to_js do
        _literal_js <<-JS
        (() => {
          const root = document.getElementById("crumble-pwa-install");
          const button = document.getElementById("crumble-pwa-install-trigger");
          const panel = document.getElementById("crumble-pwa-install-panel");
          const closeButton = document.getElementById("crumble-pwa-install-panel-close");
          if (!root || !button || !panel || !closeButton) return;

          let deferredPrompt = null;
          const mobileMedia = window.matchMedia("(max-width: 900px)");
          const isMobileAgent = /Android|iPhone|iPad|iPod|IEMobile|Opera Mini/i.test(navigator.userAgent);
          const isMobile = mobileMedia.matches || isMobileAgent;
          // iPadOS can report MacIntel, so we include the touch-point fallback.
          const isIos = /iPhone|iPad|iPod/i.test(navigator.userAgent) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
          const isSafari = /Safari/i.test(navigator.userAgent) && !/CriOS|FxiOS|EdgiOS|OPiOS|Chrome|Android/i.test(navigator.userAgent);
          const isIosSafari = isIos && isSafari;
          const isStandalone = () => window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true;

          const closePanel = () => {
            panel.hidden = true;
          };

          const openPanel = () => {
            panel.hidden = false;
          };

          const hideInstallUi = () => {
            root.hidden = true;
            closePanel();
          };

          const showInstallUi = () => {
            root.hidden = false;
          };

          if (!isMobile || isStandalone()) {
            hideInstallUi();
            return;
          }

          if (isIosSafari) showInstallUi();

          // Capture the browser's install event and defer it until button click.
          window.addEventListener("beforeinstallprompt", event => {
            event.preventDefault();
            deferredPrompt = event;
            if (!isStandalone()) showInstallUi();
          });

          window.addEventListener("appinstalled", () => {
            deferredPrompt = null;
            hideInstallUi();
          });

          closeButton.addEventListener("click", () => {
            closePanel();
          });

          // Clicking the backdrop (outside the panel card) closes the fallback.
          panel.addEventListener("click", event => {
            if (event.target === panel) closePanel();
          });

          button.addEventListener("click", async () => {
            if (isStandalone()) {
              hideInstallUi();
              return;
            }

            if (isIosSafari) {
              closePanel();
              openPanel();
              return;
            }

            if (!deferredPrompt) return;

            deferredPrompt.prompt();
            const choiceResult = await deferredPrompt.userChoice;
            deferredPrompt = null;
            if (choiceResult && (choiceResult.outcome === "accepted" || choiceResult.outcome === "dismissed")) hideInstallUi();
          });
        })();
        JS
      end
    end

    template do
      div id: "crumble-pwa-install", hidden: true do
        button id: "crumble-pwa-install-trigger", type: "button", aria: {haspopup: "dialog", controls: "crumble-pwa-install-panel"} do
          "Install app"
        end
      end

      div id: "crumble-pwa-install-panel", hidden: true do
        div id: "crumble-pwa-install-panel-dialog", role: "dialog", aria: {modal: true} do
          p { "To install this app, tap Share, then Add to Home Screen." }
          button id: "crumble-pwa-install-panel-close", type: "button", aria: {label: "Close install instructions"} do
            "Close"
          end
        end
      end

      script { Script.to_js }

      style do
        <<-CSS
        #crumble-pwa-install {
          position: fixed;
          left: 0;
          right: 0;
          bottom: 0;
          width: 100vw;
          box-sizing: border-box;
          padding: 0.5rem 0.75rem;
          background: #f6edac;
          display: flex;
          justify-content: center;
          align-items: center;
          z-index: 2147483640;
        }

        #crumble-pwa-install[hidden] {
          display: none;
        }

        #crumble-pwa-install-trigger {
          appearance: none;
          border: 0;
          border-radius: 999px;
          padding: 0.45rem 1rem;
          background: #757575;
          color: #ffffff;
          font-size: 0.9rem;
          line-height: 1;
        }

        #crumble-pwa-install-panel {
          position: fixed;
          inset: 0;
          display: flex;
          justify-content: center;
          align-items: flex-end;
          padding: 0 0.75rem 4rem;
          box-sizing: border-box;
          background: rgba(0, 0, 0, 0.3);
          z-index: 2147483641;
        }

        #crumble-pwa-install-panel[hidden] {
          display: none;
        }

        #crumble-pwa-install-panel-dialog {
          width: min(30rem, 100%);
          box-sizing: border-box;
          border-radius: 0.75rem;
          padding: 0.8rem;
          background: #ffffff;
          color: #1f2937;
          box-shadow: 0 0.5rem 1.5rem rgba(0, 0, 0, 0.2);
        }

        #crumble-pwa-install-panel-dialog p {
          margin: 0 0 0.6rem;
          font-size: 0.9rem;
        }

        #crumble-pwa-install-panel-close {
          appearance: none;
          border: 0;
          border-radius: 0.5rem;
          padding: 0.4rem 0.75rem;
          background: #757575;
          color: #ffffff;
          font-size: 0.85rem;
        }

        @media (min-width: 901px) {
          #crumble-pwa-install,
          #crumble-pwa-install-panel {
            display: none !important;
          }
        }
        CSS
      end
    end
  end
end
