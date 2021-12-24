module CSS
  enum FontWeight
    Normal
    Bold

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
