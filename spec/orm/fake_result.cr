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
    values.first?.try do |val|
      val.each_key do |key|
        yield key
      end
    end
  end

  def read(t : T.class) : T forall T
    @read_index += 1
    @values[@value_index].values[@read_index].as(T)
  end
end
