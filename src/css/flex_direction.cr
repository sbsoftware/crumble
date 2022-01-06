module CSS
  enum FlexDirection
    Row
    RowReverse
    Column
    ColumnReverse

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
