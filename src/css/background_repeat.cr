module CSS
  enum BackgroundRepeat
    Repeat
    NoRepeat
    RepeatX
    RepeatY
    Initial
    Inherit

    def to_s(io)
      io << self.to_s.dasherize
    end
  end
end
