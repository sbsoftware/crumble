require "./spec_helper"

class FakeDB
  @@queries = [] of String

  def self.queries
    @@queries
  end

  def self.query_one(query)
    @@queries << query
    yield FakeResult.new({"id" => 123_i64, "name" => "Stefanie", "age" => 18} of String => DB::Any)
  end
end

class FakeResult
  getter values : Hash(String, DB::Any)

  def initialize(@values)
    @read_index = -1
  end

  def each_column
    values.each_key do |key|
      yield key
    end
  end

  def read(t : T.class) : T forall T
    @read_index += 1
    @values.values[@read_index].as(T)
  end
end

class MyModel < Crumble::ORM
  column id : Int64?
  column name : String?

  def self.db
    FakeDB
  end
end

describe "MyModel" do
  describe ".find" do
    it "generates the correct SQL query" do
      model = MyModel.find(3)
      MyModel.db.queries.first.should eq("SELECT * FROM my_models WHERE id=3 LIMIT 1")
    end
  end
end
