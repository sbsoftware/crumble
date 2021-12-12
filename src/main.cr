require "css"
require "template/view"
require "http/server"

class MyClass < CSS::CSSClass
  backgroundColor Silver
  color Black
end

class MyOtherClass < CSS::CSSClass
  backgroundColor({0xFFu8, 0xFFu8, 0xFFu8})
  color Blue
end

class RedClass < CSS::CSSClass
  backgroundColor Red
  color White
end

class MyData
  getter theprop : String

  def initialize(@theprop = "Penis")
  end

  def theklass
    MyOtherClass
  end

  def default_view
    MyView(self).new(self)
  end
end

record MyOtherData, theprop : String, theklass : String

class MyView(T) < View(T)
  template do
    div do
      div MyClass do
        div theklass, {"data-controller" => "Something"} do
          "This is:"
          strong { theprop }
        end
      end
      div RedClass do
        div do
          "Inhalt"
        end
      end
    end
    div attrs: {"lang" => "EN"} do
      div
      div RedClass do
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
        link attrs: {"rel" => "stylesheet", "href" => "/style.css"}
      end
      body do
        site_body
      end
    end
  end
end

record SiteStructure, site_title : String, site_body : Template

server = HTTP::Server.new do |ctx|
  if ctx.request.path.includes?(".css")
    ctx.response.content_type = "text/css"
    {% begin %}
      ctx.response.print([{{ CSS::CSSClass.all_subclasses.splat }}].map(&.to_css).join("\n"))
    {% end %}
  else
    ctx.response.content_type = "text/html"
    ctx.response.print MyLayout(SiteStructure).new(SiteStructure.new("WORKING TITLE", MyData.new("important things").default_view))
  end
end

address = server.bind_tcp 8080
puts "Listening on http://#{address}"
server.listen
