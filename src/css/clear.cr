module CSS
  enum Clear
    Right
    Left
    Both

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
