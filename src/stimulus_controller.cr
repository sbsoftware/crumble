abstract class StimulusController
  macro controller(&blk)
    def self.to_s(__ctrlio__ : IO)
      __ctrlio__ << "Stimulus.register(\""
      __ctrlio__ << controller_name
      __ctrlio__ << "\", class extends Controller {\n"
      capture_code {{blk}}
      __ctrlio__ << "\n}"
    end
  end

  macro capture_code(&blk)
    {% if blk.body.is_a?(Expressions) %}
      {% for exp in blk.body.expressions %}
        capture_code do
          {{exp}}
        end
      {% end %}
    {% else %}
      __ctrlio__ << "  "
      __ctrlio__ << {{blk.body}}
    {% end %}
  end

  macro targets(*targets)
    %(static targets = [{{targets.map(&.stringify).splat}}])
  end

  macro connect(&blk)
    capture_code do
      "\n\n  connect() {\n"
      {% if blk.body.is_a?(Expressions) %}
        {% for exp in blk.body.expressions %}
          "  "
          {{exp.stringify}}
        {% end %}
      {% else %}
        "  "
        {{blk.body.stringify}}
      {% end %}
      "\n  }\n"
    end
  end

  def self.controller_name
    self.name.chomp("Controller").gsub("::", "--").dasherize
  end
end
