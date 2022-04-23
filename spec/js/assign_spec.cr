require "../spec_helper"

class AssignStringJsFile
  def self.to_s(io : IO)
    JS.capture JS::WindowContext, -1, "io" do
      foo = "bar"
      console.log(foo)
    end
  end
end

class AssignReceiverJsFile
  def self.to_s(io : IO)
    JS.capture JS::WindowContext, -1, "io" do
      foo = console
      foo.log("bar")
    end
  end
end

describe "a javascript file containing variable assignments" do
  it "can handle a string assignment" do
    expected_js = <<-JS
    var foo = "bar"
    console.log(foo)
    JS

    AssignStringJsFile.to_s.should eq(expected_js)
  end

  it "can handle a call receiver assignment" do
    expected_js = <<-JS
    var foo = console
    foo.log("bar")
    JS

    AssignReceiverJsFile.to_s.should eq(expected_js)
  end
end
