require "../css/dasherize"
require "./stimulus_controller"
require "../stimulus_controllers/*"

puts String.build { |output|
  output << <<-SCRIPT
  import { Application, Controller } from "/assets/stimulus.js"
  window.Stimulus = Application.start();
  SCRIPT
  output << "\n\n"
  {% for controller_class in StimulusController.all_subclasses %}
    output << {{controller_class}}
    output << "\n\n"
  {% end %}
}
