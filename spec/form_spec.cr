require "./spec_helper"

class Crumble::FormSpec
  class DefaultForm < Crumble::Form
    field a : String, type: :hidden
    field b : String?, type: :text
  end

  class LabeledForm < Crumble::Form
    field a : String, type: :hidden, label: "Custom A"
    field b : String?, type: :text, label: nil
    field c : String
  end

  class CustomDefaultLabelForm < Crumble::Form
    field a : String
    field b : String

    macro default_label_caption(field)
      "I18n.#{ {{field}} }"
    end
  end

  class EmptyForm < Crumble::Form
  end

  class TransformForm < Crumble::Form
    field name : String do
      before_render do |value|
        value.upcase
      end

      after_submit do |value|
        value.strip
      end
    end

    field code : String? do
      before_render do |value|
        value.try(&.upcase)
      end

      after_submit do |value|
        value.try(&.strip)
      end
    end
  end

  class AllowBlankForm < Crumble::Form
    field name : String, allow_blank: false do
      after_submit do |value|
        value.strip
      end
    end

    field optional : String?, allow_blank: false
    field count : Int32, allow_blank: false
  end

  class ControllerAttr
    def self.to_html_attrs(_tag, attrs)
      attrs["data-controller"] = "signup"
    end
  end

  class TargetAttr
    def self.to_html_attrs(_tag, attrs)
      attrs["data-controller-target"] = "name"
    end
  end

  class AttrForm < Crumble::Form
    field name : String, attrs: [
      Crumble::FormSpec::ControllerAttr,
      Crumble::FormSpec::TargetAttr,
    ]
  end

  describe "DefaultForm#to_html" do
    it "should return the correct HTML" do
      ctx = test_handler_context
      expected = <<-HTML.squish
      <label for="crumble--form-spec--default-form--a-field-id">A</label>
      <input id="crumble--form-spec--default-form--a-field-id" type="hidden" name="a" value="Blah">
      <label for="crumble--form-spec--default-form--b-field-id">B</label>
      <input id="crumble--form-spec--default-form--b-field-id" type="text" name="b" value="">
      HTML

      DefaultForm.new(ctx, a: "Blah", b: nil).to_html.should eq(expected)
    end
  end

  describe "LabeledForm#to_html" do
    it "should support custom and nil labels" do
      ctx = test_handler_context
      expected = <<-HTML.squish
      <label for="crumble--form-spec--labeled-form--a-field-id">Custom A</label>
      <input id="crumble--form-spec--labeled-form--a-field-id" type="hidden" name="a" value="Blah">
      <input id="crumble--form-spec--labeled-form--b-field-id" type="text" name="b" value="">
      <label for="crumble--form-spec--labeled-form--c-field-id">C</label>
      <input id="crumble--form-spec--labeled-form--c-field-id" type="text" name="c" value="foo">
      HTML

      LabeledForm.new(ctx, a: "Blah", b: nil, c: "foo").to_html.should eq(expected)
    end
  end

  describe "CustomDefaultLabelForm#to_html" do
    it "should allow overriding default label behavior" do
      ctx = test_handler_context
      expected = <<-HTML.squish
      <label for="crumble--form-spec--custom-default-label-form--a-field-id">I18n.a</label>
      <input id="crumble--form-spec--custom-default-label-form--a-field-id" type="text" name="a" value="x">
      <label for="crumble--form-spec--custom-default-label-form--b-field-id">I18n.b</label>
      <input id="crumble--form-spec--custom-default-label-form--b-field-id" type="text" name="b" value="y">
      HTML

      CustomDefaultLabelForm.new(ctx, a: "x", b: "y").to_html.should eq(expected)
    end
  end

  describe "EmptyForm#to_html" do
    it "should return an empty string" do
      EmptyForm.new(test_handler_context).to_html.should eq("")
    end
  end

  describe "TransformForm" do
    it "applies after_submit when assigning values" do
      ctx = test_handler_context
      form = TransformForm.new(ctx, name: "  Bob ", code: "  xy ")

      form.values.should eq({name: "Bob", code: "xy"})
    end

    it "applies before_render when rendering values" do
      ctx = test_handler_context
      form = TransformForm.new(ctx, name: "  Bob ", code: "  xy ")
      expected = <<-HTML.squish
      <label for="crumble--form-spec--transform-form--name-field-id">Name</label>
      <input id="crumble--form-spec--transform-form--name-field-id" type="text" name="name" value="BOB">
      <label for="crumble--form-spec--transform-form--code-field-id">Code</label>
      <input id="crumble--form-spec--transform-form--code-field-id" type="text" name="code" value="XY">
      HTML

      form.to_html.should eq(expected)
    end

    it "applies after_submit to values parsed from www form" do
      ctx = test_handler_context
      form = TransformForm.from_www_form(ctx, URI::Params.encode({name: "  Bob ", code: "  xy "}))

      form.values.should eq({name: "Bob", code: "xy"})
    end
  end

  describe "AttrForm#to_html" do
    it "includes additional field attribute objects on the input element" do
      ctx = test_handler_context
      expected = <<-HTML.squish
      <label for="crumble--form-spec--attr-form--name-field-id">Name</label>
      <input id="crumble--form-spec--attr-form--name-field-id" data-controller="signup" data-controller-target="name" type="text" name="name" value="Bob">
      HTML

      AttrForm.new(ctx, name: "Bob").to_html.should eq(expected)
    end
  end

  describe "AllowBlankForm" do
    it "adds errors for empty strings after after_submit" do
      ctx = test_handler_context
      form = AllowBlankForm.new(ctx, name: "   ", optional: "", count: 1)

      form.valid?.should be_false
      form.errors.should eq(["name", "optional"])
    end

    it "ignores nil values and non-string fields" do
      ctx = test_handler_context
      form = AllowBlankForm.new(ctx, name: "Bob", optional: nil, count: 0)

      form.valid?.should be_true
      form.errors.should eq([] of String)
    end
  end
end
