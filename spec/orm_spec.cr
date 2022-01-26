require "./spec_helper"

class FakeDB
  @@queries = [] of String

  def self.queries
    @@queries
  end

  def self.query_one(query)
    @@queries << query
    yield FakeResult.new([{"id" => 123_i64, "name" => "Stefanie", "age" => 18} of String => DB::Any])
  end

  def self.query(query)
    @@queries << query
    yield FakeResult.new([{"id" => 122_i64, "name" => "Lulu", "age" => 22} of String => DB::Any])
  end
end

class FakeResult
  getter values : Array(Hash(String, DB::Any))

  def initialize(@values)
    @value_index = 0
    @read_index = -1
  end

  def each
    values.size.times do
      yield
      @value_index += 1
      @read_index = -1
    end
  end

  def each_column
    values.first.each_key do |key|
      yield key
    end
  end

  def read(t : T.class) : T forall T
    @read_index += 1
    @values[@value_index].values[@read_index].as(T)
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
      MyModel.db.queries.last.should eq("SELECT * FROM my_models WHERE id=3 LIMIT 1")
    end
  end

  describe ".where" do
    it "generates the correct SQL query for String values" do
      models = MyModel.where({"name" => "Test"})
      MyModel.db.queries.last.should eq("SELECT * FROM my_models WHERE name='Test'")
    end

    it "generates the correct SQL query for Int64 values" do
      models = MyModel.where({"id" => 122_i64})
      MyModel.db.queries.last.should eq("SELECT * FROM my_models WHERE id=122")
    end

    it "generates the correct SQL query for mixed values" do
      models = MyModel.where({"id" => 122_i64, "name" => "Stefanie"})
      MyModel.db.queries.last.should eq("SELECT * FROM my_models WHERE id=122 AND name='Stefanie'")
    end
  end
end
