require "option_parser"
require "yaml"

class Crumble::CLI
  enum Command
    Init
  end

  SRC_FOLDER = "src"
  CRUMBLE_FOLDER = Path.new(SRC_FOLDER, "crumble")
  MODELS_FOLDER = Path.new(SRC_FOLDER, "models")
  VIEWS_FOLDER = Path.new(SRC_FOLDER, "views")
  RESOURCES_FOLDER = Path.new(SRC_FOLDER, "resources")
  STYLES_FOLDER = Path.new(SRC_FOLDER, "styles")

  @command : Command?
  @name : String? = parse_shard_name
  @verbose = false

  def initialize
    @parser = OptionParser.parse do |parser|
      parser.banner = "Usage: crumble [command] [options]"
      parser.on "init", "Initialize new crumble app" do
        @command = Command::Init
        parser.banner = "Usage: crumble init [options]"
        parser.on "-n", "--name NAME", "The name of the main executable" do |name|
          @name = name
        end
        parser.on "--help", "Print out help" do
          puts parser
        end
      end
      parser.on "-v", "--verbose", "Comment every step" { @verbose = true }
    end
  end

  def run
    case @command
    in Command::Init
      init
    in Nil
      puts @parser
      exit(1)
    end
  end

  def init
    ensure_dir(SRC_FOLDER)
    ensure_dir(CRUMBLE_FOLDER)
    ensure_dir(MODELS_FOLDER)
    ensure_dir(VIEWS_FOLDER)
    ensure_dir(RESOURCES_FOLDER)
    ensure_dir(STYLES_FOLDER)
    overwrite_file("#{SRC_FOLDER}/crumble_server.cr", {{read_file "#{__DIR__}/cli/templates/crumble_server.cr"}})
    if @name
      overwrite_file("#{SRC_FOLDER}/#{@name}.cr", {{read_file "#{__DIR__}/cli/templates/main.cr"}})
    else
      puts @parser
    end

    ensure_file("#{CRUMBLE_FOLDER}/session.cr", {{read_file "#{__DIR__}/cli/templates/session.cr"}})
    ensure_file("#{CRUMBLE_FOLDER}/request_context.cr", {{read_file "#{__DIR__}/cli/templates/request_context.cr"}})
    ensure_file("#{RESOURCES_FOLDER}/application_resource.cr", {{read_file "#{__DIR__}/cli/templates/application_resource.cr"}})
    ensure_file("#{RESOURCES_FOLDER}/root_resource.cr", {{read_file "#{__DIR__}/cli/templates/root_resource.cr"}})
    ensure_file("#{STYLES_FOLDER}/application_style.cr", {{read_file "#{__DIR__}/cli/templates/application_style.cr"}})
  end

  def log_verbose(str)
    STDERR.puts str
  end

  def log(str)
    puts str
  end

  def ensure_dir(path)
    if Dir.exists?(path)
      log_verbose "#{path} already exists" if @verbose
    else
      log_verbose "Creating #{path}" if @verbose
      Dir.mkdir path
    end
  end

  def ensure_file(path, default_contents)
    if File.exists?(path)
      log_verbose "#{path} already exists" if @verbose
    else
      log_verbose "Creating #{path}" if @verbose
      File.write path, default_contents
    end
  end

  def overwrite_file(path, contents)
    log_verbose "Overwriting #{path}" if @verbose
    File.write path, contents
  end

  def self.parse_shard_name
    return unless File.exists?("shard.yml")

    File.open("shard.yml") do |file|
      YAML.parse file
    end["name"].to_s
  end
end

Crumble::CLI.new.run
