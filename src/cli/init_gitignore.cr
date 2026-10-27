module Crumble::InitGitignore
  extend self

  ENTRY = "/tmp"

  def ensure_tmp
    contents = File.exists?(".gitignore") ? File.read(".gitignore") : ""
    return if contents.lines(chomp: true).includes?(ENTRY)

    File.open(".gitignore", "a") do |file|
      file << '\n' unless contents.empty? || contents.ends_with?('\n')
      file << ENTRY << '\n'
    end
  end
end
