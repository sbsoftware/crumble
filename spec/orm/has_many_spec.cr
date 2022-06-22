require "../spec_helper"

module HasManySpec
  class Item < Crumble::ORM::Base
    id_column id : Int64?

    def self.db
      FakeDB
    end
  end

  class List < Crumble::ORM::Base
    id_column id : Int64?

    has_many_of HasManySpec::Item

    def self.db
      FakeDB
    end
  end
end

describe "the list class" do
  describe "#items.to_a" do
    it "returns an empty Array for a new List" do
      list = HasManySpec::List.new
      list.id = 594
      list.has_many_spec_items.should eq([] of HasManySpec::Item)
    end

    it "executes the correct SQL query" do
      list = HasManySpec::List.new
      list.id = 594
      FakeDB.expect("SELECT * FROM has_many_spec_items WHERE has_many_spec_list_id=594")
      list.has_many_spec_items
    end
  end
end
