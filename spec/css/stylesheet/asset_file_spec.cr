require "../../spec_helper"

module CSS::Stylesheet::AssetFileSpec
  class MyStyle < CSS::Stylesheet
    rule div do
      font_size 12.px
    end
  end

  describe "MyStyle.asset_file" do
    it "should have the same .uri_path value" do
      MyStyle.uri_path.should match(/\/styles\/css__stylesheet__asset_file_spec__my_style_.+\.css/)
    end
  end
end
