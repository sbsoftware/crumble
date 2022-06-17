module Crumble::ORM
  class Attribute(T)
    getter name : Symbol
    property value : T

    delegate :to_sql_where_condition, :to_sql_update_value, :to_sql_insert_value, to: value

    def initialize(@name, @value = nil); end

    def html_attr_key
      "data-crumble-attr-#{name}"
    end

    def html_attr_value(io)
      io << value.to_s
    end

    def selector
      CSS::AttrSelector.new(html_attr_key, value.to_s)
    end
  end
end
