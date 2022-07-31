module Crumble::ORM
  class Action(M)
    getter name : String
    getter model : M

    def initialize(@model, @name); end
  end
end
