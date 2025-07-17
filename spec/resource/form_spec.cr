require "../spec_helper"

module Crumble::Resource::FormSpec
  class TestForm < Crumble::Form
    field name : String
    field description : String?
  end

  class TestResource < Crumble::Resource
    def create
      form = TestForm.from_www_form(ctx.request.body.try(&.gets_to_end) || "")

      if form.valid?
        ctx.response << "Fields: #{form.values}"
      else
        ctx.response << "Errors: #{form.errors}"
      end
    end
  end

  describe "TestResource" do
    it "should respond to valid input" do
      res = String.build do |io|
        ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: TestResource.uri_path, method: "POST", body: URI::Params.encode({name: "Foo"}))
        TestResource.handle(ctx)
        ctx.response.flush
      end

      res.should contain("Fields: {name: \"Foo\", description: nil}")
    end

    it "should respond to invalid input" do
      res = String.build do |io|
        ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: TestResource.uri_path, method: "POST", body: URI::Params.encode({description: "Foo"}))
        TestResource.handle(ctx)
        ctx.response.flush
      end

      res.should contain("Errors: [\"name\"]")
    end
  end
end
