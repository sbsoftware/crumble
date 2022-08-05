module Crumble::ORM
  abstract class Action
    URI_PATH_PREFIX = "/a"

    macro inherited
      extend ClassMethods
    end

    private module ClassMethods
      abstract def handle(ctx) : Bool
      abstract def model_class : Crumble::ORM::Base.class
      abstract def path_matcher : Regex
    end

    abstract def model
    abstract def uri_path : String
  end
end
