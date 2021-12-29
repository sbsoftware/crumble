module CSS
  enum JustifyContent
    SpaceBetween

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
