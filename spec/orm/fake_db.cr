require "./fake_result"
require "./expected_query"

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
    raise "Expected more queries!\n\n#{@@queries.join("\n")}\n\n" unless @@queries.empty?
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
