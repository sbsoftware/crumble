require "../spec_helper"

macro add_macro_before
  before do
    ctx.request.headers["X-MACRO"]? == "1"
  end
end

module Crumble::Page::BeforeSpec
  class Parent < Crumble::Page
    before do
      ctx.request.headers["X-OK"]? == "1"
    end
  end

  class DeniedPage < Parent
    before do
      true
    end

    before do
      403
    end
  end

  class AllowedPage < Parent
    view do
      template do
        p { "Success!" }
      end
    end
  end

  class MacroBeforePage < Parent
    add_macro_before

    before do
      true
    end

    view do
      template do
        p { "Macro Success!" }
      end
    end
  end

  describe "DeniedPage" do
    it "halts when parent before returns false" do
      ctx = Crumble::Server::TestRequestContext.new(resource: DeniedPage.uri_path)
      DeniedPage.handle(ctx).should eq(true)
      ctx.response.status_code.should eq(400)
    end

    it "halts with status code when a before returns an Int32" do
      headers = HTTP::Headers{"X-OK" => "1"}
      ctx = Crumble::Server::TestRequestContext.new(resource: DeniedPage.uri_path, headers: headers)
      DeniedPage.handle(ctx).should eq(true)
      ctx.response.status_code.should eq(403)
    end
  end

  describe "AllowedPage" do
    it "renders when before returns true" do
      res = String.build do |io|
        headers = HTTP::Headers{"X-OK" => "1"}
        ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: AllowedPage.uri_path, headers: headers)
        AllowedPage.handle(ctx).should eq(true)
        ctx.response.status_code.should eq(200)
        ctx.response.flush
      end

      res.should contain("Success!")
    end
  end

  describe "MacroBeforePage" do
    it "halts when macro before returns false" do
      headers = HTTP::Headers{"X-OK" => "1"}
      ctx = Crumble::Server::TestRequestContext.new(resource: MacroBeforePage.uri_path, headers: headers)
      MacroBeforePage.handle(ctx).should eq(true)
      ctx.response.status_code.should eq(400)
    end

    it "renders when macro before returns true" do
      res = String.build do |io|
        headers = HTTP::Headers{"X-OK" => "1", "X-MACRO" => "1"}
        ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: MacroBeforePage.uri_path, headers: headers)
        MacroBeforePage.handle(ctx).should eq(true)
        ctx.response.status_code.should eq(200)
        ctx.response.flush
      end

      res.should contain("Macro Success!")
    end
  end
end
