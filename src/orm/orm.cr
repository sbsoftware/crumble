require "db"
require "pg"
require "to_html"
require "./*"

module Crumble::ORM
  abstract class Base
    @@db : DB::Database?
    @@observers = [] of Proc(self, Nil)

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
      getter {{type_decl.var}} : Crumble::ORM::Attribute({{type_decl.type}}) = Crumble::ORM::Attribute({{type_decl.type}}).new({{@type.resolve}}, {{[type_decl.var.symbolize, type_decl.value].splat}})

      def {{type_decl.var}}=(new_val)
        {{type_decl.var}}.value = new_val
      end

      def self.{{type_decl.var}}(value)
        Crumble::ORM::Attribute({{type_decl.type}}).new({{@type.resolve}}, {{type_decl.var.symbolize}}, value)
      end
    end

    macro has_many_of(klass)
      def {{klass.resolve.name.underscore.gsub(/::/, "_").id}}s
        {{klass}}.where({"{{@type.name.underscore.gsub(/::/, "_").id}}_id" => id})
      end
    end

    macro template(name, &blk)
      private class {{name.id.stringify.camelcase.id}}Template
        @parent : {{@type}}

        forward_missing_to @parent

        def initialize(@parent)
        end

        ToHtml.instance_template {{blk}}
      end

      def {{name.id}}
        {{name.id.stringify.camelcase.id}}Template.new(self)
      end
    end

    def self.db
      return @@db.not_nil! if @@db

      @@db = DB.open(ENV.fetch("DATABASE_URL", "postgres://postgres@localhost/postgres"))
    end

    def self.add_observer(&block : Crumble::ORM::Base -> Nil)
      @@observers << block
    end

    def self.notify_observers(instance)
      @@observers.each do |observer|
        observer.call(instance)
      end
    end

    def notify_observers
      self.class.notify_observers(self)
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
      notify_observers
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
      {% if @type.instance_vars.any? { |v| v.name == "created_at".id } %}
        self.created_at = Time.local
      {% end %}
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

    def self.ensure_table_exists!
      db.exec table_creation_sql
    end

    def self.table_creation_sql
      String.build do |qry|
        qry << "CREATE TABLE IF NOT EXISTS "
        qry << table_name
        qry << "("
        db_column_statements.join(qry, ", ")
        qry << ")"
      end
    end

    macro db_column_statements
      [
        {% for var in @type.instance_vars.select { |v| v.annotation(Crumble::ORM::IdColumn) } %}
          "{{var.name.id}} #{db_type_for({{var.type.type_vars.first.union_types.find { |tn| tn != Nil }.id}})} PRIMARY KEY",
        {% end %}
        {% for var in @type.instance_vars.select { |v| v.annotation(Crumble::ORM::Column) } %}
          "{{var.name.id}} #{db_type_for({{var.type.type_vars.first.union_types.find { |tn| tn != Nil }.id}})}",
        {% end %}
      ] of String
    end

    def self.db_type_for(klass)
      case klass
      in Int64.class then "BIGSERIAL"
      in Int32.class then "SERIAL"
      in String.class then "VARCHAR"
      in Bool.class then "BOOLEAN"
      in Time.class then "TIMESTAMP"
      end
    end

    abstract def id
  end
end
