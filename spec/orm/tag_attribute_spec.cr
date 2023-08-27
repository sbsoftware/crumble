require "../spec_helper"

class TagAttributeModel < Crumble::ORM::Base
  id_column id : Int64?
  column name : String?

  template :default_view do
    div id do
      div name
    end
  end

  template :content_view do
    div do
      name
    end
  end
end

describe "TagAttributeModel" do
  describe "referencing attributes in HTML tags" do
    it "produces the correct HTML for no value" do
      expected_html = <<-HTML
      <div data-crumble-tag-attribute-model-id="265"><div data-crumble-tag-attribute-model-name="Carl"></div></div>
      HTML

      mdl = TagAttributeModel.new
      mdl.id = 265
      mdl.name = "Carl"
      mdl.default_view.to_html.should eq(expected_html)
    end
  end

  describe "including attributes as tag content" do
    it "produces the correct HTML" do
      expected_html = <<-HTML
      <div>Bettany</div>
      HTML

      mdl = TagAttributeModel.new
      mdl.name = "Bettany"
      mdl.content_view.to_html.should eq(expected_html)
    end
  end
end
