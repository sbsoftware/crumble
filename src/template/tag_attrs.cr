# This wrapper class is needed because of this bug:
# https://github.com/crystal-lang/crystal/issues/7164
# Otherwise we could just use plain Hashes.
class Template
  class TagAttrs
    @attrs : Hash(String, String)

    def initialize(@attrs)
    end

    def each
      @attrs.each do |k, v|
        yield({k, v})
      end
    end
  end
end
