module Crumble::ORM
  abstract class Attribute
    getter name : Symbol

    def initialize(@name)
    end

    abstract def value

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
