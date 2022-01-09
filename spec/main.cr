require "../src/crumble"
require "../src/stimulus_controllers/*"

class MyClass < CSS::CSSClass
end

class MyOtherClass < CSS::CSSClass
end

class RedClass < CSS::CSSClass
end

class MainClass < CSS::CSSClass
end

class ContentClass < CSS::CSSClass
end

class TopAppBar < CSS::ElementId
end

module TopAppBarStyle
  macro included
    rule TopAppBar do
      display Flex
      backgroundColor primary_color
      color primary_font_color
      boxShadow 3.px, 3.px, 5.px, -2.px, {0x88, 0x88, 0x88}
    end

    rule TopAppBar > any do
      padding 16.px
      margin 0
      fontSize 24.px
      fontWeight Normal
    end
  end
end

class DefaultStyle < CSS::Stylesheet
  rules do
    rule html, body, MainClass do
      width 100.percent
      height 100.percent
      padding 0
      margin 0
      fontFamily "Helvetica, sans-serif"
    end

    rule body do
      display Flex
    end

    rule MainClass do
      maxWidth 800.px
    end

    rule ContentClass do
      padding 0, 1.em
    end

    rule ul do
      backgroundColor Black
      color({0xFF, 0xFF, 0xFF})
      display Block
    end

    rule aside do
      display InlineBlock
    end

    rule ul >> a do
      color White
    end

    rule MyClass do
      backgroundColor Silver
      color Black
    end

    rule MyClass >> MyOtherClass do
      backgroundColor({0xFF, 0xFF, 0xFF})
      color Blue
    end

    rule RedClass do
      backgroundColor Red
      color White
    end

    rule MyClass >> MyOtherClass >> strong do
      display None
    end

    rule MyClass >> ul >> li >> div >> strong >> a do
      backgroundColor Blue
    end

    media(maxWidth 50.rem) do
      rule MyClass do
        display None
      end
    end
  end

  def self.primary_color
    colorValue(White)
  end

  def self.primary_font_color
    colorValue(Black)
  end
end

class Menu < CSS::CSSClass
end

class MyData
  getter theprop : String

  def initialize(@theprop = "Penis")
  end

  def theklass
    MyOtherClass
  end

  def default_view
    MyView.new(self)
  end
end

record MyOtherData, theprop : String, theklass : String

class MyView < Template
  getter my_data : MyData

  forward_missing_to my_data

  def initialize(@my_data)
  end

  template do
    div do
      div MyClass do
        div theklass, TagAttr.new("data-controller", "Something") do
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
    div(TagAttr.new("lang", "EN")) do
      div
      div RedClass do
        "Penis"
        "Vagina"
      end
    end
  end
end

StimulusInclude = {{ run("./stimulus_include").stringify }}

class PageLayout < Template
  getter page_title : String
  getter page_menu : Template
  getter page_body : Template | String

  def initialize(@page_title, @page_menu, @page_body)
  end

  template do
    html do
      head do
        title do
          page_title
        end
        style DefaultStyle
        stimulus_include StimulusInclude
      end
      body do
        page_menu
        div TopAppBar do
          page_title
        end
        div ContentClass, MainClass do
          page_body
        end
      end
    end
  end
end

class MyMenu < Template
  template do
    nav Menu do
      ul do
        li do
          resource_link RootResource, "Index"
        end
        li do
          resource_link User.find(32).user_resource_path, "Home"
        end
        li do
          resource_link SomeNamespace::SpecialResource, "Special"
        end
      end
    end
  end
end

record User, id : Int64, name : String, posts : Array(Post) do
  def self.find(id)
    post1 = Post.new("How to write a web framework in crystal", "tbd")
    post2 = Post.new("5 Reasons Why This New App Will Stun You!", "Number 3 is a real bummer!")

    new(id.to_i64, "User#{id}", [post1, post2])
  end

  def user_resource_path
    ResourcePath.new(UserResource, id)
  end

  def default_view
    DefaultUserView.new(self)
  end
end
record Post, title : String, body : String

class DefaultUserView < Template
  getter user : User

  def initialize(@user)
  end

  template do
    div do
      user.name
    end
    ul do
      user.posts.each do |post|
        li HelloController do
          div TagAttr.new("data-action", "click->hello#greet test-event@window->hello#saySomething") do
            strong HelloController.name_target do
              post.title
            end
          end
          div { post.body }
        end
      end
    end
  end
end

class RootResource < Resource
  def index
    render PageLayout.new("Index", MyMenu.new, MyData.new("Welcome!").default_view)
  end

  def self.uri_path
    "/"
  end
end

class UserResource < Resource
  def index
    user = User.find(id)

    render PageLayout.new("Home", MyMenu.new, user.default_view)
  end
end

module SomeNamespace
  class SpecialResource < Resource
    def index
      render PageLayout.new("Special", MyMenu.new, "APRIL FOOLS")
    end
  end
end

Crumble::Server.start
