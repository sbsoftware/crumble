require "./spec_helper"

describe "watch.sh" do
  shared_script = File.read(Path[__DIR__, "..", "src", "watch.sh"])
  generated_script = File.read(Path[__DIR__, "..", "src", "cli", "templates", "watch.sh"])

  it "uses Docker when its daemon and a Dockerfile are available" do
    shared_script.should contain(%(if [ -f "Dockerfile" ] && command -v docker > /dev/null 2>&1 && docker info > /dev/null 2>&1))
    shared_script.should contain("docker build")
    shared_script.should contain("docker run")
    shared_script.should contain(%(-w Dockerfile))
    shared_script.should contain(%(if [ "$PORT" != "0" ]))
  end

  it "retains the local Crystal build fallback" do
    shared_script.should contain("crystal build --error-trace")
    shared_script.should contain(%(watchexec -r -w "./bin"))
  end

  it "runs from the generated project's directory" do
    generated_script.should contain(%(cd "$SCRIPT_DIR" || exit 1))
  end

  it "has valid shell syntax" do
    Process.run("sh", ["-n", Path[__DIR__, "..", "src", "watch.sh"].to_s]).success?.should be_true
    Process.run("sh", ["-n", Path[__DIR__, "..", "src", "cli", "templates", "watch.sh"].to_s]).success?.should be_true
  end
end
