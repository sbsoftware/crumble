require "./attribute"

module Crumble::ORM
  class StringAttribute < Attribute
    property value : String?

    COLUMN_TYPE = String
  end
end
