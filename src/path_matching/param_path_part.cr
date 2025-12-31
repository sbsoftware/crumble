module Crumble::PathMatching
  struct ParamPathPart
    include PathPart

    getter name : Symbol
    getter matcher : Regex

    def initialize(name : Symbol, matcher : Regex)
      @name = name
      @matcher = matcher
    end

    def segment_pattern : String
      "(?<#{name}>#{matcher.source})"
    end
  end
end
