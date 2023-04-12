require "../spec_helper"

module BoxSizingSpec
  class ContentClass < CSS::CSSClass; end

  class Style < CSS::Stylesheet
    rules do
      rule ContentClass do
        boxSizing BorderBox
      end
    end
  end
end

describe "a style with box-sizing" do
  it "outputs correct CSS" do
    expected = <<-CSS
    .box-sizing-spec--content-class {
      box-sizing: border-box;
    }

    CSS

    BoxSizingSpec::Style.to_s.should eq(expected)
  end
end
