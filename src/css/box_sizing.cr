module CSS
  enum BoxSizing
    BorderBox

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
