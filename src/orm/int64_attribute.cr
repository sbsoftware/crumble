require "./attribute"

module Crumble::ORM
  class Int64Attribute < Attribute
    property value : Int64?

    COLUMN_TYPE = Int64
  end
end
