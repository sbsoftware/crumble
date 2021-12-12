require "template/view"

class MyData
  getter theprop : String

  def initialize(@theprop = "Penis")
  end

  def theklass
    "special"
  end

  def default_view
    MyView(self).new(self)
  end
end

record MyOtherData, theprop : String, theklass : String

class MyView(T) < View(T)
  template do
    div do
      div "bla" do
        div theklass, {"data-controller" => "Something"} do
          "This is:"
          strong { theprop }
        end
      end
      div "blu" do
        div "mama" do
          "Inhalt"
        end
      end
    end
    div attrs: {"lang" => "EN"} do
      div "gu"
      div "ga" do
        "Penis"
        "Vagina"
      end
    end
  end
end

class MyLayout(T) < View(T)
  template do
    html do
      head do
        title do
          site_title
        end
      end
      body do
        site_body
      end
    end
  end
end

record SiteStructure, site_title : String, site_body : Template

puts MyData.new("PIMMEL").default_view
puts "#####"
puts MyView(MyOtherData).new(MyOtherData.new("Suburu", "geneter"))
puts "#####"
puts MyLayout(SiteStructure).new(SiteStructure.new("3 TAGE WACH", MyView(MyData).new(MyData.new("IMPORANT DATA"))))
