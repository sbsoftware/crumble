require "./spec_helper"

class TestLayout < Template
  getter page_title : String
  getter page_body : Template | String | Nil

  def initialize(@page_title = "Test", @page_body = nil)
  end

  template do
    doctype
    html do
      head do
        title do
          page_title
        end
      end
      body do
        page_body
      end
    end
  end
end

class TestTemplate < Template
  template do
    p do
      "Test"
    end
  end
end

expected_html = <<-HTML
  <!doctype html>
  <html><head><title>Test</title>
  </head>
  <body><p>Test</p>
  </body>
  </html>

  HTML

describe "Rendering a template within another template" do
  it "generates the correct HTML" do
    tpl = TestLayout.new(page_body: TestTemplate.new)
    tpl.to_s.should eq(expected_html)
  end
end
