require "./template"

class View(T) < Template
  @model : T

  forward_missing_to @model

  def initialize(@model)
  end
end
