require "../spec_helper"

module ActionSpec
  class MyModel < Crumble::ORM::Base
    id_column id : Int64?
    column my_flag : Bool?

    boolean_flip_action :switch, :my_flag

    template :default_view do
      within switch_action.template do
        strong id do
          "something"
        end
      end
    end
  end
end

describe "the switch action" do
  it "can be applied to set true" do
    mdl = ActionSpec::MyModel.new
    mdl.my_flag = false
    mdl.switch_action.apply(true)
    mdl.my_flag.value.should eq(true)
  end

  it "can be applied to set False" do
    mdl = ActionSpec::MyModel.new
    mdl.my_flag = true
    mdl.switch_action.apply(false)
    mdl.my_flag.value.should eq(false)
  end

  it "provides a template" do
    mdl = ActionSpec::MyModel.new
    mdl.id = 77
    mdl.my_flag = true
    expected_html = <<-HTML
    <h1>SWITCH ACTION</h1>
    <div><strong data-crumble-attr-id="77">something</strong>
    </div>

    HTML
    mdl.default_view.to_s.should eq(expected_html)
  end
end
