module CSS
  enum JustifyContent
    FlexStart
    FlexEnd
    Center
    SpaceBetween
    SpaceAround
    SpaceEvenly

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
