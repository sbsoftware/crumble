require "../stimulus/stimulus_controller"

class TestEvent < JavascriptEvent
end

class HelloController < StimulusController
  targets "name", :age

  method "greet" do
    console.log("Stimulus Test")
    console.log(this.nameTarget.innerHTML)
    this.dispatch(TestEvent, window)
  end

  method "saySomething" do
    console.log("Something!")
  end
end
