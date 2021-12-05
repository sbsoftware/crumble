module CSS
  enum NamedColor
    Black
    Silver
    White
    
    def to_s
      case self
      in Black then "black"
      in Silver then "silver"
      in White then "white"
      end
    end
  end
end
