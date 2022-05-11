require "./attribute"

module Crumble::ORM
  class BoolAttribute < Attribute
    property value : Bool?

    COLUMN_TYPE = Bool
  end
end
