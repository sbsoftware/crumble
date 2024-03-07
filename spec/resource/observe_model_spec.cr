require "../spec_helper"

class ObservedModel < Crumble::ORM::Base
  id_column id : Int64?
  column name : String?

  def self.db
    FakeDB
  end
end

class ObserverResource < Crumble::Resource
  @@observations = 0

  def self.observations
    @@observations
  end

  ObservedModel.add_observer do |instance|
    res_notify(instance)
  end

  def self.res_notify(instance)
    @@observations += 1
  end
end

describe "the resource" do
  it "calls the handler" do
    ObservedModel.new.save
    ObserverResource.observations.should eq(1)
  end
end
