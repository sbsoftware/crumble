require "db"
require "pg"
require "./to_sql_val.cr"

abstract class Crumble::ORM
  @@db : DB::Database?

  annotation Crumble::ORM::IdColumn; end
  annotation Crumble::ORM::Column; end

  macro id_column(type_decl)
    @[Crumble::ORM::IdColumn]
    property {{type_decl}}
  end

  macro column(type_decl)
    @[Crumble::ORM::Column]
    property {{type_decl}}
  end

  def self.db
    return @@db.not_nil! if @@db

    @@db = DB.open(ENV.fetch("DATABASE_URL", "postgres://postgres@localhost/postgres"))
  end

  def db
    self.class.db
  end

  def self.table_name
    "#{name.underscore}s"
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
        if val.nil?
          str << " IS NULL"
        else
          str << "="
          val.to_sql_val(str)
        end
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
              @{{model_col.name}} = res.read({{model_col.type}})
          {% end %}
        else
          # ignore
        end
      {% end %}
    end
    self
  end

  def save
    if id
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
        io << "="
        if v.nil?
          io << "NULL"
        else
          v.to_sql_val(io)
        end
      end
      qry << " WHERE id="
      qry << id
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
      column_values.values.join(qry, ", ") { |v, io| v.nil? ? (io << "NULL") : v.to_sql_val(io) }
      qry << ")"
    end
    db.exec query
  end

  macro column_values
    { {{@type.instance_vars.select { |var| var.annotation(Crumble::ORM::Column) }.map { |var| "#{var.name}: @#{var.name}".id }.splat}} }
  end
end
