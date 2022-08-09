require "../spec_helper"

class CssSelectorAttributeModel < Crumble::ORM::Base
  id_column id : Int64?
  column active : Bool?
end

class AttributeSelectorStyle < CSS::Stylesheet
  rules do
    rule CssSelectorAttributeModel.active(true) do
      backgroundColor Red
    end
  end
end

describe "using model attribute classes as CSS selector" do
  it "produces the correct CSS" do
    expected_css = <<-CSS
    [data-crumble-css-selector-attribute-model-active='true'] {
      background-color: red;
    }

    CSS

    AttributeSelectorStyle.to_s.should eq(expected_css)
  end
end
