module BuildContext
  macro capture_elems(&blk)
    {% if blk %}
      {% if blk.body.is_a?(Expressions) %}
        [
        {% for exp in blk.body.expressions %}
          {{exp}},
        {% end %}
        ] of (Elmnt | String | -> String)
      {% else %}
        [
          {% if blk.body.is_a?(Call) && blk.body.name != "div" %}
            -> { _m.{{blk.body.name}} }
          {% else %}
            {{blk.body}}
          {% end %}
        ] of (Elmnt | String | -> String)
      {% end %}
    {% end %}
  end
end

class View
  @@elems = [] of (Elmnt | String | -> String)

  macro template(&blk)
    @@elems = BuildContext.capture_elems {{blk}}
  end

  macro div(css_class = nil, &block)
    {% if block %}
      Elmnt.new({{css_class}}, BuildContext.capture_elems {{block}})
    {% else %}
      Elmnt.new({{css_class}})
    {% end %}
  end

  def self.render(_m)
    @@elems.map do |elem|
      if elem.responds_to? :render
        elem.render(_m)
      else
        elem.to_s
      end
    end.join("\n")
  end
end

class Elmnt
  @tag_name : String = "div"
  @css_class : String?
  @elems : Array(Elmnt | String | -> String)

  def initialize(@css_class = nil, @elems = [] of Elmnt | String | -> String)
  end

  def render(_m) : String
    "<#{@tag_name} class=\"#{@css_class}\">#{render_elems(_m)}</#{@tag_name}>"
  end

  def render_elems(_m)
    rendered = @elems.map do |elem|
      if elem.responds_to? :render
        elem.render(_m)
      else
        elem.to_s
      end
    end.join("\n  ")

    if rendered.size > 0
      "\n  #{rendered}\n"
    else
      ""
    end
  end
end

class MyData
  @theprop : String

  def initialize(@theprop = "Penis")
  end
end

class MyView < View
  template do
    div do
      div "bla"
      div "blu"
    end
    div do
      div "gu" do
        div do
          theprop
        end
      end
      div "ga" do
        "lulu"
      end
    end
  end
end

puts MyView(MyData).render(MyData.new)
