module CSS
  enum TextDecoration
    None
    Underline

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
