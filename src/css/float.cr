module CSS
  enum Float
    Right
    Left

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
