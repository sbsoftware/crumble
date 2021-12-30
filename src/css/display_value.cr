module CSS
  enum DisplayValue
    Block
    InlineBlock
    None
    Flex
    Initial

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
