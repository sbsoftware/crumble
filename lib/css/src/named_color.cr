module CSS
  enum NamedColor
    Black
    Silver
    White
    Red
    Blue

    def to_s(io : IO)
      io << case self
            in Black then "black"
            in Silver then "silver"
            in White then "white"
            in Red then "red"
            in Blue then "blue"
            end
    end
  end
end
