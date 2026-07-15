module Crumble
  abstract class RobotsFile
    macro inherited
      File = TxtFile.new("/robots.txt", self.to_txt, immutable: false)

      def self.uri_path
        File.uri_path
      end
    end

    macro sitemap(url)
      def self.to_txt(io : IO)
        {% if @type.class.methods.map(&.name.stringify).includes?("to_txt") %}
          previous_def(io)
        {% else %}
          super(io)
        {% end %}
        write_sitemap(io, {{url}})
      end
    end

    macro user_agent(ua, &block)
      def self.to_txt(io : IO)
        {% if @type.class.methods.map(&.name.stringify).includes?("to_txt") %}
          previous_def(io)
        {% else %}
          super(io)
        {% end %}
        write_user_agent(io, {{ua}})

        # Parse the nested DSL at macro expansion time so Page/Resource constants
        # can be converted to their stable class-level uri_path automatically.
        {% expressions = block.body.is_a?(Expressions) ? block.body.expressions : [block.body] %}
        {% for exp in expressions %}
          {% unless exp.is_a?(Call) %}
            {{exp.raise "Unsupported robots directive"}}
          {% end %}

          {% if exp.name.stringify == "allow" %}
            {% unless exp.args.size == 1 %}
              {{exp.raise "allow expects exactly one path"}}
            {% end %}
            {% if exp.args[0].is_a?(Path) && (exp.args[0].resolve < ::Crumble::Page || exp.args[0].resolve < ::Crumble::Resource) %}
              write_allow(io, {{exp.args[0]}}.uri_path)
            {% else %}
              write_allow(io, {{exp.args[0]}})
            {% end %}
          {% elsif exp.name.stringify == "disallow" %}
            {% unless exp.args.size == 1 %}
              {{exp.raise "disallow expects exactly one path"}}
            {% end %}
            {% if exp.args[0].is_a?(Path) && (exp.args[0].resolve < ::Crumble::Page || exp.args[0].resolve < ::Crumble::Resource) %}
              write_disallow(io, {{exp.args[0]}}.uri_path)
            {% else %}
              write_disallow(io, {{exp.args[0]}})
            {% end %}
          {% elsif exp.name.stringify == "crawl_delay" %}
            {% unless exp.args.size == 1 %}
              {{exp.raise "crawl_delay expects exactly one number of seconds"}}
            {% end %}
            write_crawl_delay(io, {{exp.args[0]}})
          {% elsif exp.name.stringify == "sitemap" %}
            {% unless exp.args.size == 1 %}
              {{exp.raise "sitemap expects exactly one URL"}}
            {% end %}
            write_sitemap(io, {{exp.args[0]}})
          {% else %}
            {{exp.raise "Unsupported robots directive: #{exp.name}"}}
          {% end %}
        {% end %}
      end
    end

    def self.to_txt : String
      String.build do |io|
        to_txt(io)
      end
    end

    def self.to_txt(io : IO)
    end

    private def self.write_user_agent(io : IO, ua : String)
      io << "User-agent: " << ua << '\n'
    end

    private def self.write_allow(io : IO, path : String)
      write_path_directive(io, "Allow", path)
    end

    private def self.write_disallow(io : IO, path : String)
      write_path_directive(io, "Disallow", path)
    end

    private def self.write_crawl_delay(io : IO, seconds : Int32)
      io << "Crawl-delay: " << seconds << '\n'
    end

    private def self.write_sitemap(io : IO, url : String)
      io << "Sitemap: " << url << '\n'
    end

    private def self.write_path_directive(io : IO, name : String, path : String)
      io << name << ": " << path << '\n'
    end
  end
end

macro robots(&blk)
  class ::Crumble::Robots < ::Crumble::RobotsFile
    {{blk.body}}
  end
end
