require "./fake_result"

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

  def to_s(io)
    io << query
  end
end
