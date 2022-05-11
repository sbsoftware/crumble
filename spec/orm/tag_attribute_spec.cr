require "../spec_helper"

class TagAttributeModel < Crumble::ORM::Base
  id_column id : Int64?
  column name : String?

  template :default_view do
    div id do
      div name
    end
  end
end

describe "TagAttributeModel" do
  describe "referencing attributes in HTML tags" do
    it "produces the correct HTML for no value" do
      expected_html = <<-HTML
      <div data-crumble-attr-id="265"><div data-crumble-attr-name="Carl"></div>
      </div>

      HTML

      mdl = TagAttributeModel.new
      mdl.id = 265
      mdl.name = "Carl"
      mdl.default_view.to_s.should eq(expected_html)
    end
  end
end
