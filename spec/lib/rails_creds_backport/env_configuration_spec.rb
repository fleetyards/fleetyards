# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsCredsBackport::EnvConfiguration do
  subject(:config) { described_class.new }

  around do |example|
    original_values = env_keys.each_with_object({}) { |k, h| h[k] = ENV[k] }
    example.run
  ensure
    original_values.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  let(:env_keys) { %w[TEST_ONE TEST_ONE_MORE DATABASE__HOST] }

  describe "#require" do
    it "fetches an uppercased key from ENV" do
      ENV["TEST_ONE"] = "1"
      config.reload
      expect(config.require(:test_one)).to eq("1")
    end

    it "fetches nested keys joined with __" do
      ENV["DATABASE__HOST"] = "localhost"
      config.reload
      expect(config.require(:database, :host)).to eq("localhost")
    end

    it "raises KeyError for missing keys" do
      config.reload
      expect { config.require(:nonexistent_key) }.to raise_error(KeyError)
    end
  end

  describe "#option" do
    it "returns nil for missing keys" do
      config.reload
      expect(config.option(:nonexistent_key)).to be_nil
    end

    it "returns the default value for missing keys" do
      config.reload
      expect(config.option(:nonexistent_key, default: "fallback")).to eq("fallback")
    end

    it "calls a default proc for missing keys" do
      config.reload
      expect(config.option(:nonexistent_key, default: -> { "computed" })).to eq("computed")
    end

    it "returns the ENV value when present, ignoring default" do
      ENV["TEST_ONE"] = "real"
      config.reload
      expect(config.option(:test_one, default: "fallback")).to eq("real")
    end
  end

  describe "#reload" do
    it "picks up new ENV values" do
      ENV["TEST_ONE"] = "1"
      config.reload
      expect(config.require(:test_one)).to eq("1")

      ENV["TEST_ONE"] = "2"
      expect(config.require(:test_one)).to eq("1") # cached

      config.reload
      expect(config.require(:test_one)).to eq("2")
    end
  end
end
