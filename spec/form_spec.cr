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

  describe "DefaultForm#to_html" do
    it "should return the correct HTML" do
      expected = <<-HTML.squish
      <label for="crumble--form-spec--default-form--a-field-id">A</label>
      <input id="crumble--form-spec--default-form--a-field-id" type="hidden" name="a" value="Blah">
      <label for="crumble--form-spec--default-form--b-field-id">B</label>
      <input id="crumble--form-spec--default-form--b-field-id" type="text" name="b" value="">
      HTML

      DefaultForm.new(a: "Blah", b: nil).to_html.should eq(expected)
    end
  end

  describe "LabeledForm#to_html" do
    it "should support custom and nil labels" do
      expected = <<-HTML.squish
      <label for="crumble--form-spec--labeled-form--a-field-id">Custom A</label>
      <input id="crumble--form-spec--labeled-form--a-field-id" type="hidden" name="a" value="Blah">
      <input id="crumble--form-spec--labeled-form--b-field-id" type="text" name="b" value="">
      <label for="crumble--form-spec--labeled-form--c-field-id">C</label>
      <input id="crumble--form-spec--labeled-form--c-field-id" type="text" name="c" value="foo">
      HTML

      LabeledForm.new(a: "Blah", b: nil, c: "foo").to_html.should eq(expected)
    end
  end

  describe "CustomDefaultLabelForm#to_html" do
    it "should allow overriding default label behavior" do
      expected = <<-HTML.squish
      <label for="crumble--form-spec--custom-default-label-form--a-field-id">I18n.a</label>
      <input id="crumble--form-spec--custom-default-label-form--a-field-id" type="text" name="a" value="x">
      <label for="crumble--form-spec--custom-default-label-form--b-field-id">I18n.b</label>
      <input id="crumble--form-spec--custom-default-label-form--b-field-id" type="text" name="b" value="y">
      HTML

      CustomDefaultLabelForm.new(a: "x", b: "y").to_html.should eq(expected)
    end
  end

  describe "EmptyForm#to_html" do
    it "should return an empty string" do
      EmptyForm.new.to_html.should eq("")
    end
  end
end
