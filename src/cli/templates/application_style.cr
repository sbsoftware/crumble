class ApplicationStyle < CSS::Stylesheet
end

# Include it
class ToHtml::Layout
  append_to_head ApplicationStyle
end
