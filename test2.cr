class Box(T)
  getter items = [] of Item(T)

  def initialize(@items)
    @object = nil
  end
end

class Item(T)
  @item : T

  def initialize(@item)
  end
end

puts Box.new(Item.new("Bla")).items
