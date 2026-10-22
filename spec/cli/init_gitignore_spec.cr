require "../spec_helper"
require "file/tempfile"
require "../../src/cli/init_gitignore"

describe Crumble::InitGitignore do
  around_each do |example|
    temp_dir = File.tempname("crumble-init-gitignore", nil)
    Dir.mkdir(temp_dir)
    Dir.cd(temp_dir) { example.run }
  ensure
    FileUtils.rm_rf(temp_dir) if temp_dir
  end

  it "creates a gitignore containing /tmp" do
    Crumble::InitGitignore.ensure_tmp

    File.read(".gitignore").should eq("/tmp\n")
  end

  it "appends /tmp to an existing gitignore" do
    File.write(".gitignore", "/bin")

    Crumble::InitGitignore.ensure_tmp

    File.read(".gitignore").should eq("/bin\n/tmp\n")
  end

  it "does not add /tmp when it is already present" do
    File.write(".gitignore", "/bin\n/tmp\n")

    Crumble::InitGitignore.ensure_tmp

    File.read(".gitignore").should eq("/bin\n/tmp\n")
  end
end
