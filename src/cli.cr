require "option_parser"

enum Commands
  Init
end

def log_verbose(str)
  STDERR.puts str
end

command = nil
verbose = false
name = nil

def ensure_dir(path, verbose)
  if Dir.exists?(path)
    log_verbose "#{path} already exists" if verbose
  else
    log_verbose "Creating #{path}" if verbose
    Dir.mkdir path
  end
end

def ensure_file(path, verbose)
  if File.exists?(path)
    log_verbose "#{path} already exists" if verbose
  else
    log_verbose "Creating #{path}" if verbose
    File.touch path
  end
end

parser = OptionParser.parse do |parser|
  parser.banner = "Usage: crumble [command] [options]"
  parser.on "init", "Initialize new crumble app" do
    command = Commands::Init
    parser.banner = "Usage: crumble init [options] <app_name>"
    parser.unknown_args do |args, whatever|
      name = args.first?
    end
  end
  parser.on "-v", "--verbose", "Comment every step" { verbose = true }
end

src_folder = "src"

case command
in Commands::Init
  ensure_dir(src_folder, verbose)
  if name
    ensure_file("#{src_folder}/#{name}.cr", verbose)
  else
    puts parser
  end
in Nil
  puts parser
  exit(1)
end
