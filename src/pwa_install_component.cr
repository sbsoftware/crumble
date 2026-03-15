require "js"
require "to_html"

module Crumble
  class PwaInstallComponent
    include Crumble::ContextView
    css_class InstallContainer
    css_class InstallTrigger
    css_class InstallPanel
    css_class InstallPanelDialog
    css_class InstallPanelText
    css_class InstallPanelActions
    css_class InstallPanelClose
    css_class Hidden

    style Style do
      rule InstallContainer do
        position :fixed
        left 0
        right 0
        bottom 0
        width 100.vw
        box_sizing :border_box
        padding 0.5.rem, 0.75.rem
        background "#f6edac"
        display :flex
        justify_content :center
        align_items :center
        text_align :center
        z_index 2147483640
      end

      rule InstallTrigger do
        appearance "none"
        border 0
        border_radius 999.px
        padding 0.45.rem, 1.rem
        background "#757575"
        color "#ffffff"
        font_size 0.9.rem
        line_height 1
      end

      rule InstallPanel do
        position :fixed
        inset 0
        display :flex
        justify_content :center
        align_items :flex_end
        padding 1.rem, 0.75.rem, 4.rem
        box_sizing :border_box
        background rgb(0, 0, 0, alpha: 30.percent)
        z_index 2147483641
      end

      rule InstallPanelDialog do
        width 100.percent
        max_width 30.rem
        box_sizing :border_box
        border_radius 0.75.rem
        padding 0.8.rem
        background "#ffffff"
        color "#1f2937"
        box_shadow 0.px, 0.5.rem, 1.5.rem, rgb(0, 0, 0, alpha: 20.percent)
      end

      rule InstallPanelText do
        margin 0, 0, 0.6.rem
        font_size 0.9.rem
      end

      rule InstallPanelActions do
        text_align :right
      end

      rule InstallPanelClose do
        appearance "none"
        border 0
        border_radius 0.5.rem
        padding 0.4.rem, 0.75.rem
        background "#757575"
        color "#ffffff"
        font_size 0.85.rem
      end

      rule Hidden do
        display :none
      end

      media(min_width 901.px) do
        rule InstallContainer, InstallPanel do
          display :none
        end
      end
    end

    class Script < JS::Code
      def_to_js do
        root = document.querySelector(InstallContainer.to_css_selector.to_s.to_js_ref)
        button = document.querySelector(InstallTrigger.to_css_selector.to_s.to_js_ref)
        panel = document.querySelector(InstallPanel.to_css_selector.to_s.to_js_ref)
        close_button = document.querySelector(InstallPanelClose.to_css_selector.to_s.to_js_ref)

        if root && button && panel && close_button
          deferred_prompt = nil
          user_agent = navigator.userAgent
          mobile_media = window.matchMedia("(max-width: 900px)")
          is_mobile_agent = user_agent.includes("Android") || user_agent.includes("iPhone") || user_agent.includes("iPad") || user_agent.includes("iPod") || user_agent.includes("IEMobile") || user_agent.includes("Opera Mini")
          is_mobile = mobile_media.matches || is_mobile_agent

          # iPadOS can report MacIntel, so we include a touch-point check.
          is_ios = user_agent.includes("iPhone") || user_agent.includes("iPad") || user_agent.includes("iPod") || (navigator.platform == "MacIntel" && navigator.maxTouchPoints > 1)
          is_safari = user_agent.includes("Safari") && user_agent.includes("CriOS") == false && user_agent.includes("FxiOS") == false && user_agent.includes("EdgiOS") == false && user_agent.includes("OPiOS") == false && user_agent.includes("Chrome") == false && user_agent.includes("Android") == false
          is_ios_safari = is_ios && is_safari
          is_standalone = window.matchMedia("(display-mode: standalone)").matches || navigator.standalone == true
          hidden_class = Hidden.to_s.to_js_ref

          close_panel = -> { panel.classList.add(hidden_class) }
          open_panel = -> { panel.classList.remove(hidden_class) }
          hide_install_ui = -> { root.classList.add(hidden_class); close_panel._call }
          show_install_ui = -> { root.classList.remove(hidden_class) }

          if is_mobile == false || is_standalone
            hide_install_ui._call
          else
            if is_ios_safari
              show_install_ui._call
            end

            # Capture browser install intent and defer native prompt to custom CTA click.
            window.addEventListener("beforeinstallprompt", ->(event) do
              event.preventDefault._call
              deferred_prompt = event
              if window.matchMedia("(display-mode: standalone)").matches == false && navigator.standalone != true
                show_install_ui._call
              end
            end)

            window.addEventListener("appinstalled", -> do
              deferred_prompt = nil
              hide_install_ui._call
            end)

            close_button.addEventListener("click", -> do
              close_panel._call
            end)

            # Treat clicks on the backdrop (outside the panel card) as dismiss.
            panel.addEventListener("click", ->(event) do
              if event.target == panel
                close_panel._call
              end
            end)

            button.addEventListener("click", async do
              is_standalone_now = window.matchMedia("(display-mode: standalone)").matches || navigator.standalone == true

              if is_standalone_now
                hide_install_ui._call
              elsif is_ios_safari
                close_panel._call
                open_panel._call
              elsif deferred_prompt
                deferred_prompt.prompt._call
                choice_result = await(deferred_prompt.userChoice)
                deferred_prompt = nil

                if choice_result && (choice_result.outcome == "accepted" || choice_result.outcome == "dismissed")
                  hide_install_ui._call
                end
              end
            end)
          end
        end
      end
    end

    template do
      div InstallContainer, Hidden do
        button InstallTrigger, type: "button", aria: {haspopup: "dialog"} do
          "Install app"
        end
      end

      div InstallPanel, Hidden do
        div InstallPanelDialog, role: "dialog", aria: {modal: true} do
          p InstallPanelText do
            "To install this app, tap Share in the menu, then Add to Home Screen."
          end
          div InstallPanelActions do
            button InstallPanelClose, type: "button", aria: {label: "Close install instructions"} do
              "Close"
            end
          end
        end
      end

      Script
    end
  end
end
