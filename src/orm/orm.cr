require "db"
require "pg"

abstract class Crumble::ORM
  @@db : DB::Database?

  annotation Crumble::ORM::Column; end

  macro column(type_decl)
    @[Crumble::ORM::Column]
    property {{type_decl}}
  end

  def self.db
    return @@db.not_nil! if @@db

    @@db = DB.open(ENV.fetch("DATABASE_URL", "postgres://postgres@localhost/postgres"))
  end

  def self.table_name
    "#{name.underscore}s"
  end

  def self.find(id)
    db.query_one("SELECT * FROM #{table_name} WHERE id=#{id} LIMIT 1") do |res|
      new.load_result(res)
    end
  end

  def self.all
    db.query("SELECT * FROM #{table_name}") do |res|
      instances = [] of self
      res.each do
        instances << new.load_result(res)
      end
      instances
    end
  end

  def load_result(res)
    res.each_column do |column|
      {% begin %}
        case column
          {% for model_col in @type.instance_vars.select { |var| var.annotation(Crumble::ORM::Column) } %}
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
end
