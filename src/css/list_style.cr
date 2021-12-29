module CSS
  enum ListStyle
    None

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
