require "./spec_helper"

class Crumble::FormSpec
  class MyForm < Crumble::Form
    field a : String, type: :hidden
    field b : String?, type: :text
    field c : String
    field d : Bool, type: :hidden
  end

  class EmptyForm < Crumble::Form
  end

  describe "MyForm#to_html" do
    it "should return the correct HTML" do
      expected = <<-HTML.squish
      <input type="hidden" name="a" value="Blah">
      <input type="text" name="b" value="">
      <input type="text" name="c" value="foo">
      <input type="hidden" name="d" value="true">
      HTML

      MyForm.new(a: "Blah", b: nil, c: "foo", d: true).to_html.should eq(expected)
    end
  end

  describe "EmptyForm#to_html" do
    it "should return an empty string" do
      EmptyForm.new.to_html.should eq("")
    end
  end
end
