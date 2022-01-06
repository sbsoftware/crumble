module CSS
  enum BorderStyle
    None
    Hidden
    Dotted
    Dashed
    Solid
    Double
    Groove
    Ridge
    Inset
    Outset
    Initial
    Inherit

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
