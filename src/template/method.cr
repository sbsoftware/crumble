class Template
  enum Method
    Get
    Post
    Put
    Patch
    Delete

    def to_s
      super.upcase
    end

    def to_tag_attr
      {"method", self}
    end
  end
end
