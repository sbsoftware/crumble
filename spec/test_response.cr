class TestResponse
  @io : Array(String)

  def initialize
    @io = [] of String
  end

  def <<(str)
    @io << str.to_s
  end

  def strings
    @io.dup
  end

  def to_s(io)
    @io.each do |str|
      io << str
    end
  end
end
