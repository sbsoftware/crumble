require "./action"

module Crumble::ORM
  class BooleanFlipAction(M) < Action(M)
    getter attribute : Proc(M, Crumble::ORM::Attribute(Bool?))

    delegate :to_s, to: template

    def initialize(@model, @name, @attribute); end

    def apply(new_val : Bool)
      attribute.call(model).value = new_val
    end

    private class Template < ::Template
      template do
        h1 { "SWITCH ACTION" }
        div do
          main_docking_point
        end
      end
    end

    def template
      Template.new
    end
  end
end
