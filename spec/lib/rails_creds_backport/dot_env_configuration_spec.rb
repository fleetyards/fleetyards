# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsCredsBackport::DotEnvConfiguration do
  let(:tmpdir) { Dir.mktmpdir("dotenv-test-") }
  let(:env_path) { File.join(tmpdir, ".env") }

  after { FileUtils.rm_rf(tmpdir) }

  def write_env(content)
    File.write(env_path, content)
    described_class.new(env_path)
  end

  describe "#require" do
    it "reads a simple key=value" do
      config = write_env("DB_HOST=localhost")
      expect(config.require(:db_host)).to eq("localhost")
    end

    it "reads nested keys with __" do
      config = write_env("DATABASE__HOST=localhost")
      expect(config.require(:database, :host)).to eq("localhost")
    end

    it "raises KeyError for missing keys" do
      config = write_env("")
      expect { config.require(:missing) }.to raise_error(KeyError)
    end
  end

  describe "parsing" do
    it "handles double-quoted values" do
      config = write_env('MESSAGE="hello world"')
      expect(config.require(:message)).to eq("hello world")
    end

    it "handles single-quoted values" do
      config = write_env("MESSAGE='hello world'")
      expect(config.require(:message)).to eq("hello world")
    end

    it "handles escaped newlines in double quotes" do
      config = write_env('MESSAGE="hello\nworld"')
      expect(config.require(:message)).to eq("hello\nworld")
    end

    it "ignores comments and blank lines" do
      config = write_env("# comment\n\nONE=1\n\nTWO=2")
      expect(config.require(:one)).to eq("1")
      expect(config.require(:two)).to eq("2")
    end

    it "allows spaces around =" do
      config = write_env("ONE = 1")
      expect(config.require(:one)).to eq("1")
    end

    it "interpolates variables" do
      config = write_env("HOST=localhost\nPORT=5432\nURL=postgres://${HOST}:${PORT}/db")
      expect(config.require(:url)).to eq("postgres://localhost:5432/db")
    end

    it "executes shell commands" do
      config = write_env("SECRET=$(echo hello)")
      expect(config.require(:secret)).to eq("hello")
    end

    it "returns empty hash for nonexistent file" do
      config = described_class.new(File.join(tmpdir, "nonexistent.env"))
      expect(config.option(:anything)).to be_nil
    end
  end

  describe "#reload" do
    it "picks up file changes" do
      config = write_env("ONE=1")
      expect(config.require(:one)).to eq("1")

      File.write(env_path, "ONE=2")
      expect(config.require(:one)).to eq("1")

      config.reload
      expect(config.require(:one)).to eq("2")
    end
  end
end
