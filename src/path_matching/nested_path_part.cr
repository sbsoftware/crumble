module Crumble::PathMatching
  struct NestedPathPart
    include PathPart

    getter segment : String

    def initialize(segment : String)
      @segment = segment.gsub(/\A\/+|\/+\z/, "")
    end

    def segment_pattern : String
      Regex.escape(segment)
    end
  end
end
