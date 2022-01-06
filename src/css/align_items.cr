module CSS
  enum AlignItems
    FlexStart
    FlexEnd
    Center
    Stretch
    Baseline

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
