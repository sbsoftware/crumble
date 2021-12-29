require "./selector"

module CSS
  class TagSelector < Selector
    @tag_name : String

    def initialize(@tag_name)
    end

    def to_s(io : IO)
      io << @tag_name
    end
  end
end
