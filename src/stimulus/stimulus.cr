require "./stimulus_controller"

puts String.build { |output|
  output << <<-SCRIPT
  import { Application, Controller } from "#{StimulusFile.uri_path}"
  window.Stimulus = Application.start();
  SCRIPT
  output << "\n\n"
  {% for controller_class in StimulusController.all_subclasses %}
    output << {{controller_class}}
    output << "\n\n"
  {% end %}
}
