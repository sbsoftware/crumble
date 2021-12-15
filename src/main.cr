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

class TopAppBar < CSS::CSSClass
end

class Menu < CSS::CSSClass
end

class Content < CSS::CSSClass
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

record SiteStructure, site_title : String, site_body : Template do
  def layout
    MyLayout(self).new(self)
  end
end

class PageTemplate(T) < View(T)
  template do
    page_menu
    div TopAppBar do
      page_title
    end
    div Content do
      page_body
    end
  end
end

record PageStructure, page_title : String, page_menu : Template, page_body : Template do
  def template
    PageTemplate(self).new(self)
  end
end

class MyMenu < Template
  template do
    nav Menu do
      ul do
        li do
          a attrs: {"href" => "/" } do
            "Index"
          end
        end
        li do
          a attrs: {"href" => "/home"} do
            "Home"
          end
        end
      end
    end
  end
end

record User, name : String, posts : Array(Post)
record Post, title : String, body : String

post1 = Post.new("How to write a web framework in crystal", "tbd")
post2 = Post.new("5 Reasons Why This New App Will Stun You!", "Number 3 is a real bummer!")
user1 = User.new("MoetiMoe", [post1, post2])

record HomeContent, user : User do
  def template
    HomeTemplate(self).new(self)
  end
end

class HomeTemplate(T) < View(T)
  template do
    div do
      user.name
    end
    ul do
      user.posts.each do |post|
        li do
          div do
            strong { post.title }
          end
          div { post.body }
        end
      end
    end
  end
end

server = HTTP::Server.new do |ctx|
  if ctx.request.path.includes?("style.css")
    ctx.response.content_type = "text/css"
    {% begin %}
      ctx.response.print([{{ CSS::CSSClass.all_subclasses.splat }}].map(&.to_css).join("\n"))
    {% end %}
  elsif ctx.request.path == "/"
    ctx.response.content_type = "text/html"
    ctx.response.print SiteStructure.new("WORKING TITLE", PageStructure.new("Index", MyMenu.new, MyData.new("Welcome!").default_view).template).layout
  elsif ctx.request.path == "/home"
    ctx.response.content_type = "text/html"
    ctx.response.print SiteStructure.new("WORKING TITLE", PageStructure.new("Home", MyMenu.new, HomeContent.new(user1).template).template).layout
  end
end

address = server.bind_tcp 8080
puts "Listening on http://#{address}"
server.listen
