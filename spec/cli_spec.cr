require "./spec_helper"
require "file_utils"

describe "crumble init" do
  it "creates a default .env and a watch script that sources it" do
    dir = File.join(Dir.tempdir, "crumble-cli-spec-#{Random.rand(1_000_000)}")
    Dir.mkdir(dir)
    cache_dir = File.join(dir, ".crystal-cache")
    Dir.mkdir(cache_dir)

    begin
      error = IO::Memory.new
      status = Process.run("crystal", ["run", File.expand_path("../src/cli.cr", __DIR__), "--", "init", "--name", "sample_app", "--port", "4321"], env: {"CRYSTAL_CACHE_DIR" => cache_dir}, chdir: dir, output: Process::Redirect::Close, error: error)
      raise error.to_s unless status.success?

      File.read(File.join(dir, ".env")).should eq("DATABASE_URL=\"sqlite3://./data.db\"\nORMA_CONTINUOUS_MIGRATION=1\n")
      File.read(File.join(dir, "watch.sh")).should eq(<<-SH)
        #!/usr/bin/env sh

        SCRIPT_DIR=$(dirname "$0")

        if [ -f "$SCRIPT_DIR/.env" ]; then
          # Export sourced assignments so the delegated watcher inherits them.
          set -a
          . "$SCRIPT_DIR/.env"
          set +a
        fi

        exec "$SCRIPT_DIR/lib/crumble/src/watch.sh" "sample_app" "4321"

        SH
    ensure
      FileUtils.rm_rf(dir)
    end
  end
end
