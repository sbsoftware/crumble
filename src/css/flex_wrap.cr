module CSS
  enum FlexWrap
    Nowrap
    Wrap
    WrapReverse

    def to_s(io : IO)
      io << self.to_s.dasherize
    end
  end
end
