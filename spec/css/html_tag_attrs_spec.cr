require "../spec_helper"
require "to_html"

module CSS::HtmlTagAttrsSpec
  css_id MyId
  css_class PrimaryClass
  css_class SecondaryClass

  class MyView
    ToHtml.class_template do
      label MyId, PrimaryClass do
        "Field 1"
      end

      select_tag MyId, PrimaryClass, SecondaryClass do
        option(value: "one") { "One" }
        option(value: "two") { "Two" }
      end

      div [PrimaryClass, SecondaryClass] do
        "Multiple classes"
      end

      span PrimaryClass, class: "other" do
        "With other class"
      end

      span PrimaryClass, SecondaryClass do
        "Multiple arguments"
      end
    end
  end

  describe "MyView.to_html" do
    it "adds CSS ids and classes to HTML tag attributes" do
      expected = <<-HTML.squish
      <label for="css--html-tag-attrs-spec--my-id" class="css--html-tag-attrs-spec--primary-class">Field 1</label>
      <select id="css--html-tag-attrs-spec--my-id" class="css--html-tag-attrs-spec--primary-class css--html-tag-attrs-spec--secondary-class">
        <option value="one">One</option>
        <option value="two">Two</option>
      </select>
      <div class="css--html-tag-attrs-spec--primary-class css--html-tag-attrs-spec--secondary-class">Multiple classes</div>
      <span class="css--html-tag-attrs-spec--primary-class other">With other class</span>
      <span class="css--html-tag-attrs-spec--primary-class css--html-tag-attrs-spec--secondary-class">Multiple arguments</span>
      HTML

      MyView.to_html.should eq(expected)
    end
  end
end
