require "../template"
require "./*"

module CSS
  abstract class Stylesheet
    @@rules = {} of CSS::Selector => String

    macro rules(&blk)
      def self.to_s(__rulesio__ : IO)
        capture_rules {{blk}}
      end
    end

    macro capture_rules(level = 0, &blk)
      {% if blk.body.is_a?(Expressions) %}
        {% for exp in blk.body.expressions %}
          capture_rule({{level}}) do
            {{exp}}
          end
        {% end %}
      {% else %}
        capture_rule({{level}}) {{blk}}
      {% end %}
    end

    macro capture_rule(level = 0, &blk)
      {% if blk.body.name.stringify == "media" && level == 0 %}
        __rulesio__ << "@media ("
        {% for arg in blk.body.args %}
          __rulesio__ << {{arg}}
        {% end %}
        __rulesio__ << ") {\n"
        capture_rules({{level + 1}}) {{blk.body.block}}
        __rulesio__ << "}\n"
      {% else %}
        __rulesio__ << " " * {{level}} * 2
        __rulesio__ << make_selector({{blk.body.args.splat}})
        __rulesio__ << " {\n"
        {% if blk.body.block.body.is_a?(Expressions) %}
          {% for exp in blk.body.block.body.expressions %}
            __rulesio__ << " " * {{(level + 1) * 2}}
            __rulesio__ << {{exp}}
            __rulesio__ << ";\n"
          {% end %}
        {% else %}
          __rulesio__ << " " * {{(level + 1) * 2}}
          __rulesio__ << {{blk.body.block.body}}
          __rulesio__ << ";\n"
        {% end %}
        __rulesio__ << " " * {{level}} * 2
        __rulesio__ << "}\n"
      {% end %}
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
        {% elsif sel.receiver && sel.name.stringify == "&" %}
          CSS::CombinedSelector.new(make_selector({{sel.receiver}}), make_selector({{sel.args.first}}))
        {% elsif sel.receiver && sel.name.stringify == "<=" %}
          CSS::PseudoclassSelector.new(make_selector({{sel.receiver}}), CSS::Pseudoclass::{{sel.args.first}})
        {% else %}
          {{pp sel.receiver}}
          {{pp sel.name}}
          {{pp sel.args}}
          {% raise "Unknown tag name: #{sel.id.stringify}" %}
        {% end %}
      {% elsif sel.is_a?(Expressions) %}
        make_selector({{sel.expressions.last}})
      {% elsif sel.is_a?(TupleLiteral) %}
        CSS::SumSelector.new([{{sel.map { |s| "make_selector(#{s}).as(CSS::Selector)".id }.splat}}].as(Array(CSS::Selector)))
      {% else %}
        {{pp sel.name}}
        {% raise "Unknown selector type: #{sel.stringify}" %}
      {% end %}
    end

    macro make_selector(*sels)
      make_selector({{sels}})
    end

    macro backgroundColor(c)
      prop("background-color", colorValue({{c}}))
    end

    macro backgroundImage(asset_file)
      prop("background-image", "url(#{{{asset_file}}.uri_path})")
    end

    macro color(c)
      prop("color", colorValue({{c}}))
    end

    macro textDecoration(td)
      prop("text-decoration", CSS::TextDecoration::{{td}})
    end

    macro display(dv)
      prop("display", CSS::DisplayValue::{{dv}})
    end

    macro position(pos)
      prop("position", CSS::Position::{{pos}})
    end

    macro zIndex(zi)
      prop("z-index", {{zi}})
    end

    macro top(t)
      prop("top", {{t}})
    end

    macro left(l)
      prop("left", {{l}})
    end

    macro width(w)
      prop("width", {{w}})
    end

    macro minWidth(mw)
      prop("min-width", {{mw}})
    end

    macro height(h)
      prop("height", {{h}})
    end

    macro minHeight(mh)
      prop("min-height", {{mh}})
    end

    macro padding(*p)
      prop("padding", padding_value({{p.splat}}))
    end

    macro margin(m)
      prop("margin", {{m}})
    end

    macro marginLeft(ml)
      prop("margin-left", {{ml}})
    end

    macro marginRight(mr)
      prop("margin-right", {{mr}})
    end

    macro marginTop(mt)
      prop("margin-top", {{mt}})
    end

    macro marginBottom(mb)
      prop("margin-bottom", {{mb}})
    end

    macro border(*b)
      prop("border", border_value({{b.splat}}))
    end

    macro borderTop(*bt)
      prop("border-top", border_value({{bt.splat}}))
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

    macro listStyle(ls)
      prop("list-style", CSS::ListStyle::{{ls}})
    end

    macro alignItems(ai)
      prop("align-items", CSS::AlignItems::{{ai}})
    end

    macro flexDirection(fd)
      prop("flex-direction", CSS::FlexDirection::{{fd}})
    end

    macro flexGrow(fg)
      prop("flex-grow", {{fg}})
    end

    macro flexWrap(fw)
      prop("flex-wrap", CSS::FlexWrap::{{fw}})
    end

    macro flexBasis(fb)
      prop("flex-basis", {{fb}})
    end

    macro justifyContent(jc)
      prop("justify-content", CSS::JustifyContent::{{jc}})
    end

    macro content(c)
      prop("content", {{c.stringify}})
    end

    macro colorValue(c)
      {% if c.is_a?(Path) %}
        CSS::NamedColor::{{c}}
      {% elsif c.is_a?(TupleLiteral) %}
        HexColor.new({{c}})
      {% elsif c.is_a?(NumberLiteral) %}
        HexColor.new({ {{c}}, {{c}}, {{c}} })
      {% else %}
        {{c}}
      {% end %}
    end

    macro border_value(size, style, color)
      "#{{{size}}} #{CSS::BorderStyle::{{style}}} #{colorValue({{color}})}"
    end

    macro prop(name, value)
      "{{name.id}}: #{{{value}}}"
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
