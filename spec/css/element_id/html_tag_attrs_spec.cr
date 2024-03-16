require "../../spec_helper"
require "to_html"

module CSS::ElementId::HtmlTagAttrsSpec
  class MyId < CSS::ElementId
  end

  class MyView
    ToHtml.class_template do
      label MyId do
        "Field 1"
      end
      select_tag MyId do
        option(value: "one") { "One" }
        option(value: "two") { "Two" }
      end
    end
  end

  describe "MyView.to_html" do
    it "should return the correct HTML" do
      expected = <<-HTML.squish
      <label for="css--element-id--html-tag-attrs-spec--my-id">Field 1</label>
      <select id="css--element-id--html-tag-attrs-spec--my-id">
        <option value="one">One</option>
        <option value="two">Two</option>
      </select>
      HTML

      MyView.to_html.should eq(expected)
    end
  end
end
