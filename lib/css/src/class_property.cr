module CSS
  abstract class ClassProperty
    abstract def name  
    abstract def value
    
    def to_s
      "#{name}: #{value.to_s}"
    end
  end
end
