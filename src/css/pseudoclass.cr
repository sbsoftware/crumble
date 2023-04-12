module CSS
  enum Pseudoclass
    Before
    After
    Empty

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
