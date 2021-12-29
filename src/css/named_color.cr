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
    Inherit

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
