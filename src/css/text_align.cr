module CSS
  enum TextAlign
    Left
    Right
    Center
    Justify
    Initial
    Inherit

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
