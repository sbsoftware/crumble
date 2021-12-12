module CSS
  abstract class ClassProperty
    abstract def name  
    abstract def value
    
    def to_s(io : IO)
      io << name
      io << ": "
      io << value
    end
  end
end
