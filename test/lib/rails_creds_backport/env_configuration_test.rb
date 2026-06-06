# frozen_string_literal: true

require "test_helper"

module RailsCredsBackport
  class EnvConfigurationTest < ActiveSupport::TestCase
    ENV_KEYS = %w[TEST_ONE TEST_ONE_MORE DATABASE__HOST].freeze

    setup do
      @original_env = ENV_KEYS.each_with_object({}) { |k, h| h[k] = ENV[k] }
      @config = EnvConfiguration.new
    end

    teardown do
      @original_env.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    end

    test "#require fetches an uppercased key from ENV" do
      ENV["TEST_ONE"] = "1"
      @config.reload
      assert_equal "1", @config.require(:test_one)
    end

    test "#require fetches nested keys joined with __" do
      ENV["DATABASE__HOST"] = "localhost"
      @config.reload
      assert_equal "localhost", @config.require(:database, :host)
    end

    test "#require raises KeyError for missing keys" do
      @config.reload
      assert_raises(KeyError) { @config.require(:nonexistent_key) }
    end

    test "#option returns nil for missing keys" do
      @config.reload
      assert_nil @config.option(:nonexistent_key)
    end

    test "#option returns the default value for missing keys" do
      @config.reload
      assert_equal "fallback", @config.option(:nonexistent_key, default: "fallback")
    end

    test "#option calls a default proc for missing keys" do
      @config.reload
      assert_equal "computed", @config.option(:nonexistent_key, default: -> { "computed" })
    end

    test "#option returns the ENV value when present, ignoring default" do
      ENV["TEST_ONE"] = "real"
      @config.reload
      assert_equal "real", @config.option(:test_one, default: "fallback")
    end

    test "#reload picks up new ENV values" do
      ENV["TEST_ONE"] = "1"
      @config.reload
      assert_equal "1", @config.require(:test_one)

      ENV["TEST_ONE"] = "2"
      assert_equal "1", @config.require(:test_one) # cached

      @config.reload
      assert_equal "2", @config.require(:test_one)
    end
  end
end
