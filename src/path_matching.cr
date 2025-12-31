require "./path_matching/path_part"
require "./path_matching/nested_path_part"
require "./path_matching/param_path_part"

module Crumble::PathMatching
  macro root_path(path)
    def self._root_path
      {{path}}
    end
  end

  macro path_param(name, matcher = /\d+/)
    PATH_PARTS << Crumble::PathMatching::ParamPathPart.new({{name.id.symbolize}}, {{matcher}})

    def {{name.id}} : String
      path_params[{{name.id.stringify}}]
    end
  end

  macro nested_path(path)
    PATH_PARTS << Crumble::PathMatching::NestedPathPart.new({{path}})
  end

  macro included
    @path_params : Hash(String, String)?

    PATH_PARTS = [] of Crumble::PathMatching::PathPart

    def self._path_matching_root_suffix : String
      ""
    end

    def self._path_parts : Array(Crumble::PathMatching::PathPart)
      PATH_PARTS
    end

    macro inherited
      PATH_PARTS = [] of Crumble::PathMatching::PathPart

      def self._path_parts : Array(Crumble::PathMatching::PathPart)
        PATH_PARTS
      end
    end

    def self.match(path)
      uri_path_matcher.match(path)
    end

    def self._root_path
      suffix = _path_matching_root_suffix
      base_name = suffix.empty? ? self.name : self.name.chomp(suffix)
      "/" + base_name.gsub("::", "/").underscore
    end

    def self.uri_path(**params)
      param_values = {} of Symbol => String
      params.each do |key, value|
        param_values[key] = value.to_s
      end

      segments = _root_path.split('/').reject(&.empty?)

      _path_parts.each do |part|
        case part
        when Crumble::PathMatching::NestedPathPart
          segments << part.segment
        when Crumble::PathMatching::ParamPathPart
          value = param_values.delete(part.name) || raise ArgumentError.new("Missing path param '#{part.name}' for #{self}")
          segments << value
        end
      end

      if param_values.size > 0
        unused = param_values.keys.map(&.to_s).sort
        raise ArgumentError.new("Unused path params for #{self}: #{unused.join(", ")}")
      end

      "/" + segments.join("/")
    end

    def self.uri_path_matcher
      root_segments = _root_path.split('/').reject(&.empty?)
      segment_patterns = root_segments.map { |seg| Regex.escape(seg) }

      segment_patterns.concat(_path_parts.map(&.segment_pattern))

      if segment_patterns.empty?
        /^\/$/
      else
        Regex.new("^/" + segment_patterns.join("/") + "/?$")
      end
    end

    protected def path_params : Hash(String, String)
      @path_params ||= begin
        match = self.class.match(ctx.request.path)
        return ({} of String => String) unless match

        match.named_captures.compact
      end
    end
  end
end
