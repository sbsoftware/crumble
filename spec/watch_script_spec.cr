require "./spec_helper"

describe "watch.sh" do
  shared_script = File.read(Path[__DIR__, "..", "src", "watch.sh"])
  generated_script = File.read(Path[__DIR__, "..", "src", "cli", "templates", "watch.sh"])

  it "uses Docker when its daemon and a Dockerfile are available" do
    shared_script.should contain(%(if [ -f "Dockerfile" ] && command -v docker > /dev/null 2>&1 && docker info > /dev/null 2>&1))
    shared_script.should contain("docker build")
    shared_script.should contain("docker run")
    shared_script.should contain(%(-w Dockerfile))
    shared_script.should contain(%(-w Dockerfile -w .env))
    shared_script.should contain(%(if [ "$PORT" != "0" ]))
  end

  it "restarts source changes inside the existing container" do
    shared_script.should contain(%(-v '$PWD:/workspace' -w /workspace))
    shared_script.should contain(%(watchexec -r --poll 1000 -w src -w lib -e cr))
    shared_script.should_not contain(%(-w shard.yml))
    shared_script.should_not contain(%(-w shard.lock))
  end

  it "runs once with a hint when the image does not contain watchexec" do
    shared_script.should contain(%(if command -v watchexec > /dev/null 2>&1))
    shared_script.should contain("watchexec missing in image; running without restart-on-change")
    shared_script.should contain(%(exec crystal run --error-trace "$SRC_FILENAME" -- -p "$PORT"))
  end

  it "rebuilds only when Dockerfile changes" do
    shared_script.should contain("--emit-events-to=environment")
    shared_script.should contain(%(grep -q 'Dockerfile'))
    shared_script.should contain(%(. ./.env))
    shared_script.should contain("EVENT_PATHS")
    shared_script.should contain("::::")
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
