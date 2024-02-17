class FakeDB
  @@queries = [] of ExpectedQuery

  def self.reset
    @@queries.clear
  end

  def self.queries
    @@queries
  end

  def self.expect(query)
    expected_query = ExpectedQuery.new(query)
    @@queries << expected_query
    expected_query
  end

  def self.assert_empty!
    raise "Expected more queries!" unless @@queries.empty?
  end

  def self.query_one(str)
    _query(str) do |res|
      yield res
    end
  end

  def self.query(str)
    _query(str) do |res|
      yield res
    end
  end

  def self.exec(str)
    _query(str) do
      # do nothing
    end
  end

  private def self._query(str)
    query = @@queries.shift?
    raise "Expected query\n\"#{query.query}\"\nbut got\n\"#{str}\"\ninstead" if query && query.query != str
    yield query.try &.result || FakeResult.new([] of Hash(String, DB::Any))
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

class ExpectedQuery
  getter query : String
  getter result : FakeResult?

  def initialize(@query)
  end

  macro and_return(*hashes)
    set_result({{ hashes.map { |h| "#{h} of String => DB::Any".id } }}.splat)
  end

  def set_result(data : Array(Hash(String, DB::Any)))
    @result = FakeResult.new(data)
  end
end
