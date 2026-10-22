require "./spec_helper"

describe "watch.sh" do
  it "has valid shell syntax" do
    Process.run("sh", ["-n", Path[__DIR__, "..", "src", "watch.sh"].to_s]).success?.should be_true
    Process.run("sh", ["-n", Path[__DIR__, "..", "src", "cli", "templates", "watch.sh"].to_s]).success?.should be_true
  end
end
