module CSS
  enum BackgroundSize
    Auto
    Cover
    Contain
    Initial
    Inherit

    def to_s(io)
      io << self.to_s.dasherize
    end
  end
end
