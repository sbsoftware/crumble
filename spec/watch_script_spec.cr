require "file_utils"
require "./spec_helper"

describe "watch.sh" do
  it "falls back to one run when the container does not have watchexec" do
    directory = File.tempname("watch-script-spec")
    bin_directory = Path[directory, "bin"]
    Dir.mkdir_p(bin_directory)
    crystal = bin_directory / "crystal"
    File.write(crystal, "#!/bin/sh\nprintf 'crystal:%s\\n' \"$*\"\n")
    File.chmod(crystal, 0o755)
    output = IO::Memory.new
    error = IO::Memory.new

    begin
      Process.run("/bin/sh", [Path[__DIR__, "..", "src", "watch.sh"].to_s, "--docker-container", "src/example.cr", "0"], env: {"PATH" => bin_directory.to_s}, output: output, error: error).success?.should be_true
      output.to_s.should eq("crystal:run --error-trace src/example.cr -- -p 0\n")
      error.to_s.should contain("watchexec missing in image; running without restart-on-change")
    ensure
      FileUtils.rm_rf(directory)
    end
  end

  it "starts the polling source watcher when watchexec is available" do
    directory = File.tempname("watch-script-spec")
    bin_directory = Path[directory, "bin"]
    Dir.mkdir_p(bin_directory)
    watchexec = bin_directory / "watchexec"
    File.write(watchexec, "#!/bin/sh\nprintf 'watchexec:%s\\n' \"$*\"\n")
    File.chmod(watchexec, 0o755)
    output = IO::Memory.new

    begin
      Process.run("/bin/sh", [Path[__DIR__, "..", "src", "watch.sh"].to_s, "--docker-container", "src/example.cr", "3000"], env: {"PATH" => bin_directory.to_s}, output: output).success?.should be_true
      output.to_s.should contain("watchexec:-r --poll 1000 -w src -w lib -e cr -- sh")
      output.to_s.should contain("--docker-run src/example.cr 3000")
    ensure
      FileUtils.rm_rf(directory)
    end
  end
end
