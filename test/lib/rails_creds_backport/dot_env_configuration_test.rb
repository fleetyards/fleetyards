# frozen_string_literal: true

require "test_helper"

module RailsCredsBackport
  class DotEnvConfigurationTest < ActiveSupport::TestCase
    setup do
      @tmpdir = Dir.mktmpdir("dotenv-test-")
      @env_path = File.join(@tmpdir, ".env")
    end

    teardown do
      FileUtils.rm_rf(@tmpdir)
    end

    def write_env(content)
      File.write(@env_path, content)
      DotEnvConfiguration.new(@env_path)
    end

    test "#require reads a simple key=value" do
      config = write_env("DB_HOST=localhost")
      assert_equal "localhost", config.require(:db_host)
    end

    test "#require reads nested keys with __" do
      config = write_env("DATABASE__HOST=localhost")
      assert_equal "localhost", config.require(:database, :host)
    end

    test "#require raises KeyError for missing keys" do
      config = write_env("")
      assert_raises(KeyError) { config.require(:missing) }
    end

    test "parsing handles double-quoted values" do
      config = write_env('MESSAGE="hello world"')
      assert_equal "hello world", config.require(:message)
    end

    test "parsing handles single-quoted values" do
      config = write_env("MESSAGE='hello world'")
      assert_equal "hello world", config.require(:message)
    end

    test "parsing handles escaped newlines in double quotes" do
      config = write_env('MESSAGE="hello\nworld"')
      assert_equal "hello\nworld", config.require(:message)
    end

    test "parsing ignores comments and blank lines" do
      config = write_env("# comment\n\nONE=1\n\nTWO=2")
      assert_equal "1", config.require(:one)
      assert_equal "2", config.require(:two)
    end

    test "parsing allows spaces around =" do
      config = write_env("ONE = 1")
      assert_equal "1", config.require(:one)
    end

    test "parsing interpolates variables" do
      config = write_env("HOST=localhost\nPORT=5432\nURL=postgres://${HOST}:${PORT}/db")
      assert_equal "postgres://localhost:5432/db", config.require(:url)
    end

    test "parsing executes shell commands" do
      config = write_env("SECRET=$(echo hello)")
      assert_equal "hello", config.require(:secret)
    end

    test "parsing returns empty hash for nonexistent file" do
      config = DotEnvConfiguration.new(File.join(@tmpdir, "nonexistent.env"))
      assert_nil config.option(:anything)
    end

    test "#reload picks up file changes" do
      config = write_env("ONE=1")
      assert_equal "1", config.require(:one)

      File.write(@env_path, "ONE=2")
      assert_equal "1", config.require(:one)

      config.reload
      assert_equal "2", config.require(:one)
    end
  end
end
