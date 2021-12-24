module CSS
  enum NamedColor
    Black
    Silver
    White
    Red
    Blue
    Teal
    Olive
    Gold

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
