module Crumble::ORM
  class Attribute(T)
    getter name : Symbol
    property value : T

    delegate :to_sql_where_condition, :to_sql_update_value, :to_sql_insert_value, to: value

    def initialize(@name, @value = nil); end

    def to_tag_attr
      {"data-crumble-attr-#{name}", value}
    end

    def selector
      CSS::AttrSelector.new(to_tag_attr.first, value.to_s)
    end
  end
end
