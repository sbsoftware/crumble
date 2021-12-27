require "./named_color"
require "./font_weight"
require "./hex_color"
require "./display_value"
require "./selector"
require "./tag_selector"
require "./id_selector"
require "./class_selector"
require "./nested_selector"
require "./child_selector"
require "./any_selector"
require "./sum_selector"

module CSS
  abstract class Stylesheet
    @@rules = {} of CSS::Selector => String

    macro rule(selector, &blk)
      @@rules[make_selector({{selector}})] = String.build do |__rulesio__|
        {{blk.body}}
      end
    end

    macro rule(*selector, &blk)
      rule({{selector}}) {{blk}}
    end

    macro make_selector(sel)
      {% if sel.is_a?(StringLiteral) %}
        CSS::TagSelector.new({{sel}})
      {% elsif sel.is_a?(Path) %}
        {{sel}}.selector
      {% elsif sel.is_a?(Call) %}
        {% if (Template::CONTENT_TAG_NAMES + Template::STANDALONE_TAG_NAMES).includes?(sel.id.stringify) %}
          CSS::TagSelector.new({{sel.id.stringify}})
        {% elsif sel.id.stringify == "any" %}
          CSS::AnySelector.new
        {% elsif sel.receiver && sel.name.stringify == ">>" %}
          CSS::NestedSelector.new(make_selector({{sel.receiver}}), make_selector({{sel.args.first}}))
        {% elsif sel.receiver && sel.name.stringify == ">" %}
          CSS::ChildSelector.new(make_selector({{sel.receiver}}), make_selector({{sel.args.first}}))
        {% else %}
          {{pp sel.receiver}}
          {{pp sel.name}}
          {{pp sel.args}}
          {% raise "Unknown tag name: #{sel.id.stringify}" %}
        {% end %}
      {% elsif sel.is_a?(Expressions) %}
        make_selector({{sel.expressions.last}})
      {% elsif sel.is_a?(TupleLiteral) %}
        CSS::SumSelector.new([{{sel.map { |s| "make_selector(#{s})".id }.splat}}].as(Array(CSS::Selector)))
      {% else %}
        {{pp sel.name}}
        {% raise "Unknown selector type: #{sel.stringify}" %}
      {% end %}
    end

    macro backgroundColor(c)
      prop("background-color", colorValue({{c}}))
    end

    macro color(c)
      prop("color", colorValue({{c}}))
    end

    macro display(dv)
      prop("display", CSS::DisplayValue::{{dv}})
    end

    macro width(w)
      prop("width", {{w}})
    end

    macro height(h)
      prop("height", {{h}})
    end

    macro padding(*p)
      prop("padding", padding_value({{p.splat}}))
    end

    macro margin(m)
      prop("margin", {{m}})
    end

    macro fontFamily(ff)
      prop("font-family", {{ff}})
    end

    macro fontSize(fs)
      prop("font-size", {{fs}})
    end

    macro fontWeight(fw)
      prop("font-weight", CSS::FontWeight::{{fw}})
    end

    macro maxWidth(mw)
      prop("max-width", {{mw}})
    end

    macro boxShadow(offset_x, offset_y, blur_radius, spread_radius, color)
      prop("box-shadow", "#{{{offset_x}}} #{{{offset_y}}} #{{{blur_radius}}} #{{{spread_radius}}} #{colorValue({{color}})}")
    end

    macro colorValue(c)
      {% if c.is_a?(Path) %}
        CSS::NamedColor::{{c}}
      {% elsif c.is_a?(TupleLiteral) %}
        HexColor.new({{c}})
      {% else %}
        {{c}}
      {% end %}
    end

    macro prop(name, value)
      __rulesio__ << {{name}}
      __rulesio__ << ": "
      __rulesio__ << {{value}}
      __rulesio__ << ";\n"
    end

    def self.to_s(io : IO)
      @@rules.each do |(sel, rules)|
        io << sel
        io << " {\n"
        io << rules
        io << "}\n"
      end
    end

    def self.padding_value(val)
      val.to_s
    end

    def self.padding_value(val1, val2)
      "#{val1} #{val2}"
    end

    def self.padding_value(val1, val2, val3)
      "#{val1} #{val2} #{val3}"
    end

    def self.padding_value(val1, val2, val3, val4)
      "#{val1} #{val2} #{val3} #{val4}"
    end

    def self.uri_path
      "/styles/#{self.name.underscore}.css"
    end
  end
end
