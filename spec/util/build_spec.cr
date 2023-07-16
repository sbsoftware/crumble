require "../spec_helper"

module BuildSpec
  class MyClass
    property attr1 : Int32?
    property attr2 : String?

    def initialize(@attr1 = nil, @attr2 = nil)
    end
  end
end

describe "when initializing a class with .build" do
  it "should transform variable assignments into arguments" do
    my_class = BuildSpec::MyClass.build do
      attr1 = 4
    end

    my_class.should be_a(BuildSpec::MyClass)
    my_class.attr1.should eq(4)
    my_class.attr2.should be_nil
  end

  it "should transform calls with blocks into arguments" do
    my_class = BuildSpec::MyClass.build do
      attr2 do
        this = "this"
        is = "is"
        sparta = "sparta"
        [this, is, sparta].join(" ")
      end
    end

    my_class.should be_a(BuildSpec::MyClass)
    my_class.attr2.should eq("this is sparta")
    my_class.attr1.should be_nil
  end

  it "should support a mix of variable assignments and calls with blocks" do
    my_class = BuildSpec::MyClass.build do
      attr1 = 17
      attr2 do
        str = "ich bin ein berliner"
        str.split(" ").map(&.capitalize).join(" ")
      end
    end

    my_class.should be_a(BuildSpec::MyClass)
    my_class.attr1.should eq(17)
    my_class.attr2.should eq("Ich Bin Ein Berliner")

    my_class2 = BuildSpec::MyClass.build do
      attr1 do
        a = 1
        b = 2
        a + b
      end
      attr2 = "Der Zug hat keine Bremsen"
    end

    my_class2.should be_a(BuildSpec::MyClass)
    my_class2.attr2.should eq("Der Zug hat keine Bremsen")
    my_class2.attr1.should eq(3)
  end
end
