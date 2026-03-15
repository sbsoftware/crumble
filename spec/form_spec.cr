require "./spec_helper"

class Crumble::FormSpec
  class FieldWrapperStyle < CSS::Stylesheet
    rule Crumble::Field do
      font_size 12.px
    end
  end

  describe "FieldWrapperStyle" do
    it "can reference Crumble::Field from styles outside the form" do
      asset_file = AssetFileRegistry.query(FieldWrapperStyle.uri_path).not_nil!
      asset_file.contents.should eq(".crumble--field {\n  font-size: 12px;\n}")
    end
  end

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

  class CustomValidationForm < Crumble::Form
    field my_field : String? do
      validation do
        if my_field != "my_value"
          add_error("No match!")
          add_error("Expected my_value")
        end
      end
    end

    field some_field : String?
    field other_field : String?

    validation do
      if some_field != "foo" && other_field == "blah"
        add_error("Wrong")
        add_error("Still wrong")
      end
    end
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

  class HtmlAttrsForm < Crumble::Form
    field amount : String, attrs: {required: true, step: ".01", placeholder: "Amount"}
  end

  class MixedAttrsForm < Crumble::Form
    field amount : String, attrs: [
      Crumble::FormSpec::ControllerAttr,
      {required: true, step: ".01"},
      Crumble::FormSpec::TargetAttr,
      {placeholder: "Amount"},
    ]
  end

  class NonInputControlsForm < Crumble::Form
    field role : String?, type: :select, options: {
      "user"  => "User",
      "admin" => "Admin",
    }

    field bio : String?, type: :textarea
  end

  describe "DefaultForm#to_html" do
    it "should return the correct HTML" do
      ctx = test_handler_context
      expected = <<-HTML.squish
      <input id="crumble--form-spec--default-form--a-field-id" type="hidden" name="a" value="Blah">
      <div class="crumble--field">
        <label for="crumble--form-spec--default-form--b-field-id">B</label>
        <input id="crumble--form-spec--default-form--b-field-id" type="text" name="b" value="">
      </div>
      HTML

      DefaultForm.new(ctx, a: "Blah", b: nil).to_html.should eq(expected)
    end
  end

  describe "LabeledForm#to_html" do
    it "should support custom and nil labels" do
      ctx = test_handler_context
      expected = <<-HTML.squish
      <input id="crumble--form-spec--labeled-form--a-field-id" type="hidden" name="a" value="Blah">
      <div class="crumble--field">
        <input id="crumble--form-spec--labeled-form--b-field-id" type="text" name="b" value="">
      </div>
      <div class="crumble--field">
        <label for="crumble--form-spec--labeled-form--c-field-id">C</label>
        <input id="crumble--form-spec--labeled-form--c-field-id" type="text" name="c" value="foo">
      </div>
      HTML

      LabeledForm.new(ctx, a: "Blah", b: nil, c: "foo").to_html.should eq(expected)
    end
  end

  describe "CustomDefaultLabelForm#to_html" do
    it "should allow overriding default label behavior" do
      ctx = test_handler_context
      expected = <<-HTML.squish
      <div class="crumble--field">
        <label for="crumble--form-spec--custom-default-label-form--a-field-id">I18n.a</label>
        <input id="crumble--form-spec--custom-default-label-form--a-field-id" type="text" name="a" value="x">
      </div>
      <div class="crumble--field">
        <label for="crumble--form-spec--custom-default-label-form--b-field-id">I18n.b</label>
        <input id="crumble--form-spec--custom-default-label-form--b-field-id" type="text" name="b" value="y">
      </div>
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
      <div class="crumble--field">
        <label for="crumble--form-spec--transform-form--name-field-id">Name</label>
        <input id="crumble--form-spec--transform-form--name-field-id" type="text" name="name" value="BOB">
      </div>
      <div class="crumble--field">
        <label for="crumble--form-spec--transform-form--code-field-id">Code</label>
        <input id="crumble--form-spec--transform-form--code-field-id" type="text" name="code" value="XY">
      </div>
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
      <div class="crumble--field">
        <label for="crumble--form-spec--attr-form--name-field-id">Name</label>
        <input id="crumble--form-spec--attr-form--name-field-id" data-controller="signup" data-controller-target="name" type="text" name="name" value="Bob">
      </div>
      HTML

      AttrForm.new(ctx, name: "Bob").to_html.should eq(expected)
    end
  end

  describe "HtmlAttrsForm#to_html" do
    it "includes HTML attributes defined via attrs hash" do
      ctx = test_handler_context
      expected = <<-HTML.squish
      <div class="crumble--field">
        <label for="crumble--form-spec--html-attrs-form--amount-field-id">Amount</label>
        <input id="crumble--form-spec--html-attrs-form--amount-field-id" step=".01" placeholder="Amount" type="text" name="amount" value="12.34" required>
      </div>
      HTML

      HtmlAttrsForm.new(ctx, amount: "12.34").to_html.should eq(expected)
    end
  end

  describe "MixedAttrsForm#to_html" do
    it "accepts a mix of attribute providers and HTML attributes" do
      ctx = test_handler_context
      expected = <<-HTML.squish
      <div class="crumble--field">
        <label for="crumble--form-spec--mixed-attrs-form--amount-field-id">Amount</label>
        <input id="crumble--form-spec--mixed-attrs-form--amount-field-id" data-controller="signup" step=".01" data-controller-target="name" placeholder="Amount" type="text" name="amount" value="12.34" required>
      </div>
      HTML

      MixedAttrsForm.new(ctx, amount: "12.34").to_html.should eq(expected)
    end
  end

  describe "NonInputControlsForm#to_html" do
    it "renders select and textarea fields in the native template" do
      ctx = test_handler_context
      expected = <<-HTML.squish
      <div class="crumble--field">
        <label for="crumble--form-spec--non-input-controls-form--role-field-id">Role</label>
        <select id="crumble--form-spec--non-input-controls-form--role-field-id" name="role"><option value="user">User</option><option value="admin" selected>Admin</option></select>
      </div>
      <div class="crumble--field">
        <label for="crumble--form-spec--non-input-controls-form--bio-field-id">Bio</label>
        <textarea id="crumble--form-spec--non-input-controls-form--bio-field-id" name="bio">Hello</textarea>
      </div>
      HTML

      NonInputControlsForm.new(ctx, role: "admin", bio: "Hello").to_html.should eq(expected)
    end
  end

  describe "AllowBlankForm" do
    it "checks built-in validity on fresh forms but does not render errors" do
      ctx = test_handler_context
      form = AllowBlankForm.new(ctx, name: "   ", optional: "", count: 1)

      form.valid?.should be_false
      form.errors.should eq(["name", "optional"])
      form.to_html.should_not contain("crumble--field-errors")
    end

    it "adds errors for empty strings after after_submit" do
      ctx = test_handler_context
      form = AllowBlankForm.from_www_form(ctx, URI::Params.encode({name: "   ", optional: "", count: "1"}))

      form.valid?.should be_false
      form.errors.should eq(["name", "optional"])
    end

    it "ignores nil values and non-string fields" do
      ctx = test_handler_context
      form = AllowBlankForm.from_www_form(ctx, URI::Params.encode({name: "Bob", count: "0"}))

      form.valid?.should be_true
      form.errors.should eq([] of String)
    end
  end

  describe "CustomValidationForm" do
    it "runs custom validations on fresh forms but does not render errors" do
      ctx = test_handler_context
      form = CustomValidationForm.new(ctx, my_field: "x", some_field: "bar", other_field: "blah")

      form.valid?.should be_false
      form.errors.should eq(["No match!", "Expected my_value", "Wrong", "Still wrong"])
      form.to_html.should_not contain("crumble--form-errors")
      form.to_html.should_not contain("crumble--field-errors")
    end

    it "collects field and form errors in deterministic order on submit" do
      ctx = test_handler_context
      form = CustomValidationForm.from_www_form(ctx, URI::Params.encode({my_field: "x", some_field: "bar", other_field: "blah"}))

      form.valid?.should be_false
      form.error_entries.should eq([
        {:my_field, "No match!"},
        {:my_field, "Expected my_value"},
        {:_base, "Wrong"},
        {:_base, "Still wrong"},
      ])
      form.errors.should eq(["No match!", "Expected my_value", "Wrong", "Still wrong"])
    end

    it "renders _base errors at the top and field errors below the field" do
      ctx = test_handler_context
      form = CustomValidationForm.from_www_form(ctx, URI::Params.encode({my_field: "x", some_field: "bar", other_field: "blah"}))
      form.valid?
      expected = <<-HTML.squish
      <div class="crumble--form-errors"><ul><li>Wrong</li><li>Still wrong</li></ul></div>
      <div class="crumble--field">
        <label for="crumble--form-spec--custom-validation-form--my-field-field-id">My_field</label>
        <input id="crumble--form-spec--custom-validation-form--my-field-field-id" type="text" name="my_field" value="x">
        <ul class="crumble--field-errors"><li>No match!</li><li>Expected my_value</li></ul>
      </div>
      <div class="crumble--field">
        <label for="crumble--form-spec--custom-validation-form--some-field-field-id">Some_field</label>
        <input id="crumble--form-spec--custom-validation-form--some-field-field-id" type="text" name="some_field" value="bar">
      </div>
      <div class="crumble--field">
        <label for="crumble--form-spec--custom-validation-form--other-field-field-id">Other_field</label>
        <input id="crumble--form-spec--custom-validation-form--other-field-field-id" type="text" name="other_field" value="blah">
      </div>
      HTML

      form.to_html.should eq(expected)
    end

    it "shows no validation errors for valid submitted input" do
      ctx = test_handler_context
      form = CustomValidationForm.from_www_form(ctx, URI::Params.encode({my_field: "my_value", some_field: "foo", other_field: "blah"}))

      form.valid?.should be_true
      form.errors.should eq([] of String)
      form.to_html.should_not contain("crumble--form-errors")
      form.to_html.should_not contain("crumble--field-errors")
    end
  end
end
