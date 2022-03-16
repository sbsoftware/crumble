require "../spec_helper"

class IfJsFile
  def self.to_s(io : IO)
    JS.capture JS::WindowContext, -1, "io" do
      if 1 + 1 == 2
        console.log("Correct")
      end
    end
  end
end

expected_js = <<-JS
if (1 + 1 === 2) {
  console.log("Correct")
}
JS

describe "a javascript file containing an if statement" do
  it "transpiles to the correct javascript code" do
    IfJsFile.to_s.should eq(expected_js)
  end
end
