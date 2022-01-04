module CSS
  enum Position
    Absolute
    Relative

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
