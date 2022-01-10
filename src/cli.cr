require "option_parser"
require "yaml"

class Crumble::CLI
  enum Command
    Init
  end

  SRC_FOLDER = "src"
  VIEWS_FOLDER = Path.new(SRC_FOLDER, "views")
  STIMULUS_FOLDER = Path.new(SRC_FOLDER, "stimulus_controllers")

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
    ensure_dir(VIEWS_FOLDER)
    ensure_dir(STIMULUS_FOLDER)
    ensure_file("#{SRC_FOLDER}/crumble_server.cr", {{read_file "#{__DIR__}/cli/templates/crumble_server.cr"}})
    if @name
      ensure_file("#{SRC_FOLDER}/#{@name}.cr", "")
    else
      puts @parser
    end
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

  def self.parse_shard_name
    return unless File.exists?("shard.yml")

    File.open("shard.yml") do |file|
      YAML.parse file
    end["name"].to_s
  end
end

Crumble::CLI.new.run
