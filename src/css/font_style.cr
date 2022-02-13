module CSS
  enum FontStyle
    Normal
    Italic
    Oblique
    Initial
    Inherit

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
