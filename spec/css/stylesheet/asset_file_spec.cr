require "../../spec_helper"

module CSS::Stylesheet::AssetFileSpec
  class MyStyle < CSS::Stylesheet
    rules do
      rule div do
        fontSize 12.px
      end
    end
  end

  describe "MyStyle.asset_file" do
    it "should have the same .uri_path value" do
      MyStyle.asset_file.uri_path.should eq(MyStyle.uri_path)
    end
  end
end
