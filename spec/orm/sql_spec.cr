require "../spec_helper"
require "./fake_db"

class MyModel < Crumble::ORM::Base
  id_column id : Int64?
  column name : String?

  def self.db
    FakeDB
  end
end

describe "MyModel" do
  before_each do
    FakeDB.reset
  end

  after_each do
    FakeDB.assert_empty!
  end

  describe ".find" do
    it "generates the correct SQL query" do
      FakeDB.expect("SELECT * FROM my_models WHERE id=3 LIMIT 1")
      model = MyModel.find(3)
    end
  end

  describe ".where" do
    it "generates the correct SQL query for String values" do
      FakeDB.expect("SELECT * FROM my_models WHERE name='Test'")
      models = MyModel.where({"name" => "Test"})
    end

    it "generates the correct SQL query for Int64 values" do
      FakeDB.expect("SELECT * FROM my_models WHERE id=122")
      models = MyModel.where({"id" => 122_i64})
    end

    it "generates the correct SQL query for mixed values" do
      FakeDB.expect("SELECT * FROM my_models WHERE id=122 AND name='Stefanie'")
      models = MyModel.where({"id" => 122_i64, "name" => "Stefanie"})
    end
  end

  describe "#save" do
    context "when the instance has an id" do
      it "generates an update statement" do
        my_model = MyModel.new
        my_model.id = 122_i64
        my_model.name = "Katrina"
        FakeDB.expect("UPDATE my_models SET name='Katrina' WHERE id=122")
        my_model.save
      end
    end

    context "when the instance has no id" do
      it "generates an insert statement" do
        my_model = MyModel.new
        my_model.name = "Sabrina"
        FakeDB.expect("INSERT INTO my_models(name) VALUES ('Sabrina')")
        my_model.save
      end
    end
  end

  describe ".ensure_table_exists!" do
    it "should execute the correct CREATE TABLE statement" do
      FakeDB.expect("CREATE TABLE IF NOT EXISTS my_models(id BIGSERIAL PRIMARY KEY, name VARCHAR)")
      MyModel.ensure_table_exists!
    end
  end
end
