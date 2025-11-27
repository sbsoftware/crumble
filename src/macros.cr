macro style(name = Style, &blk)
  class {{name.id}} < CSS::Stylesheet
    {{blk.body}}
  end

  class ::ToHtml::Layout
    {% if @type == @top_level %}
      append_to_head ::{{name.id}}
    {% else %}
      append_to_head ::{{@type.name(generic_args: false)}}::{{name.id}}
    {% end %}
  end
end
