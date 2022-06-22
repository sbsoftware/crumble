require "db"
require "pg"
require "./*"

module Crumble::ORM
  abstract class Base
    @@db : DB::Database?

    annotation Crumble::ORM::IdColumn; end
    annotation Crumble::ORM::Column; end

    macro id_column(type_decl)
      @[Crumble::ORM::IdColumn]
      _column({{type_decl}})
    end

    macro column(type_decl)
      @[Crumble::ORM::Column]
      _column({{type_decl}})
    end

    macro _column(type_decl)
      getter {{type_decl.var}} : Crumble::ORM::Attribute({{type_decl.type}}) = Crumble::ORM::Attribute({{type_decl.type}}).new({{[type_decl.var.symbolize, type_decl.value].splat}})

      def {{type_decl.var}}=(new_val)
        {{type_decl.var}}.value = new_val
      end

      def self.{{type_decl.var}}(value)
        Crumble::ORM::Attribute({{type_decl.type}}).new({{type_decl.var.symbolize}}, value)
      end
    end

    macro has_many_of(klass)
      def {{klass.resolve.name.underscore.gsub(/::/, "_").id}}s
        {{klass}}.where({"{{@type.name.underscore.gsub(/::/, "_").id}}_id" => id})
      end
    end

    def self.db
      return @@db.not_nil! if @@db

      @@db = DB.open(ENV.fetch("DATABASE_URL", "postgres://postgres@localhost/postgres"))
    end

    def db
      self.class.db
    end

    def self.table_name
      {{ @type.name.underscore.gsub(/::/, "_").stringify + "s"}}
    end

    def table_name
      self.class.table_name
    end

    def self.find(id)
      query_one("SELECT * FROM #{table_name} WHERE id=#{id} LIMIT 1")
    end

    def self.all
      query_many("SELECT * FROM #{table_name}")
    end

    def self.where(conditions)
      query_many("SELECT * FROM #{table_name} WHERE #{conditions_string(conditions)}")
    end

    def self.conditions_string(conditions)
      String.build do |str|
        conditions.each_with_index do |(col, val), i|
          str << col
          val.to_sql_where_condition(str)
          str << " AND " unless i == conditions.size - 1
        end
      end
    end

    def self.query_many(sql)
      db.query(sql) do |res|
        load_many_from_result(res)
      end
    end

    def self.query_one(sql)
      db.query_one(sql) do |res|
        new.load_one_from_result(res)
      end
    end

    def self.load_many_from_result(res)
      instances = [] of self
      res.each do
        instances << new.load_one_from_result(res)
      end
      instances
    end

    def load_one_from_result(res)
      res.each_column do |column|
        {% begin %}
          case column
            {% for model_col in @type.instance_vars.select { |var| var.annotation(Crumble::ORM::Column) || var.annotation(Crumble::ORM::IdColumn) } %}
              when {{model_col.name.stringify}}
                self.{{model_col.name}} = res.read(typeof(@{{model_col.name}}.value))
            {% end %}
          else
            puts "Unknown column name #{column}"
          end
        {% end %}
      end
      self
    end

    def save
      if id.value
        update_record
      else
        insert_record
      end
    end

    def update_record
      query = String.build do |qry|
        qry << "UPDATE "
        qry << table_name
        qry << " SET "
        column_values.to_h.join(qry, ", ") do |(k, v), io|
          io << k
          v.to_sql_update_value(io)
        end
        qry << " WHERE id="
        qry << id.value
      end
      db.exec query
    end

    def insert_record
      query = String.build do |qry|
        qry << "INSERT INTO "
        qry << table_name
        qry << "("
        column_values.keys.join(qry, ", ")
        qry << ") VALUES ("
        column_values.values.join(qry, ", ") { |v, io| v.to_sql_insert_value(io) }
        qry << ")"
      end
      db.exec query
    end

    macro column_values
      { {{@type.instance_vars.select { |var| var.annotation(Crumble::ORM::Column) }.map { |var| "#{var.name}: @#{var.name}.value".id }.splat}} }
    end
  end
end
