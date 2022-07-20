require "../spec_helper"

module WithinSpec
  class SomeClass < CSS::CSSClass; end

  class SomePartial < Template
    template do
      div SomeClass do
        main_docking_point
      end
    end
  end

  class SomeTemplate < Template
    template do
      h1 { "This is big" }
      within SomePartial do
        strong { "very big" }
      end
    end
  end
end

describe WithinSpec::SomeTemplate do
  it "returns the correct HTML string" do
    expected_html = <<-HTML
    <h1>This is big</h1>
    <div class="within-spec::some-class"><strong>very big</strong>
    </div>

    HTML

    WithinSpec::SomeTemplate.new.to_s.should eq(expected_html)
  end
end
