require "./action"

module Crumble::ORM
  abstract class BooleanFlipAction < Action
    abstract def attribute

    delegate :to_s, to: template

    def apply(new_val : Bool)
      attribute.value = new_val
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

    def self.handle(ctx) : Bool
      match = path_matcher.match(ctx.request.path)
      return false unless match

      id = match[1]
      new_val = case ctx.request.method
                when "POST" then true
                when "DELETE" then false
                else true
                end

      model = model_class.find(id)
      self.new(model).apply(new_val)
      model.save

      true
    end
  end
end
