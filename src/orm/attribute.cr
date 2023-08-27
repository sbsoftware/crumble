module Crumble::ORM
  class Attribute(T)
    getter model : Crumble::ORM::Base.class
    getter name : Symbol
    property value : T

    delegate :to_sql_where_condition, :to_sql_update_value, :to_sql_insert_value, to: value

    def initialize(@model, @name, @value = nil); end

    def value=(new_val : Attribute(T))
      self.value = new_val.value
    end

    def to_html_attrs(_tag, attrs)
      attrs[html_attr_name] = value.to_s
    end

    def selector
      CSS::AttrSelector.new(html_attr_name, value.to_s)
    end

    private def html_attr_name
      "data-crumble-#{model.name.dasherize}-#{name}"
    end

    def to_s(io)
      io << value
    end
  end
end
