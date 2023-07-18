require "../spec_helper"

module FontFaceSpec
  class Style < CSS::Stylesheet
    rules do
      font_face do
        fontFamily "Helvetica"
        src url("https://example.com/helvetica.ttf")
      end
    end
  end
end

describe "a style with a font face definition" do
  it "outputs correct CSS" do
    expected = <<-CSS
    @font-face {
      font-family: "Helvetica";
      src: url("https://example.com/helvetica.ttf");
    }

    CSS

    FontFaceSpec::Style.to_s.should eq(expected)
  end
end
