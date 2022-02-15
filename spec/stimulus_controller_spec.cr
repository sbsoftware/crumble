require "./spec_helper"

class TestController < StimulusController
  targets :foo, :bar
  values :wiggle

  method :do_it do
    console.log(this.wiggleValue)
    console.log(this.fooTarget.innerHTML)
  end
end

expected_javascript = <<-JS
Stimulus.register("test", class extends Controller {
  static targets = ["foo", "bar"]
  static values = {wiggle: String}

  do_it() {
    console.log(this.wiggleValue)
    console.log(this.fooTarget.innerHTML)
  }
})
JS

describe "the test stimulus controller" do
  it "transpiles to the correct javascript code" do
    TestController.to_s.should eq(expected_javascript)
  end
end
