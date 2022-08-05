require "./action"

module Crumble::ORM
  class ActionRegistry
    ACTION_CLASSES = [] of Action.class

    macro add(action_class)
      {% ACTION_CLASSES << action_class %}
    end

    def self.handle(ctx)
      req_path = ctx.request.path
      return false unless req_path.starts_with?(Action::URI_PATH_PREFIX)

      {% for act in ACTION_CLASSES %}
        return true if {{act}}.handle(ctx)
      {% end %}
    end
  end
end
