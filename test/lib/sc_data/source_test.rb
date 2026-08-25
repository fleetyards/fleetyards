# frozen_string_literal: true

require "test_helper"

module ScData
  class SourceTest < ActiveSupport::TestCase
    # Mocha undoes this on teardown, so nothing here leaks into another test.
    private def with_config(version:, environment:)
      Rails.configuration.stubs(:sc_data).returns({version:, environment:})

      yield
    end

    test ".current reads the build and environment out of the configuration" do
      with_config(version: "4.9.0-live.1", environment: "live") do
        source = ::ScData::Source.current

        assert_equal "4.9.0-live.1", source.version
        assert_equal "live", source.environment
      end
    end

    test ".version and .environment delegate to the current source" do
      with_config(version: "4.10.0-ptu.2", environment: "ptu") do
        assert_equal "4.10.0-ptu.2", ::ScData::Source.version
        assert_equal "ptu", ::ScData::Source.environment
      end
    end

    # Not memoized on purpose: `bin/scdata parse` rewrites the config and then
    # goes on to load in the same process, so a cached value would have it
    # loading the build it replaced.
    test ".current follows a configuration change rather than caching the first read" do
      first = with_config(version: "4.9.0-live.1", environment: "live") { ::ScData::Source.version }
      second = with_config(version: "4.10.0-ptu.2", environment: "ptu") { ::ScData::Source.version }

      assert_equal "4.9.0-live.1", first
      assert_equal "4.10.0-ptu.2", second
    end

    # Two sources are the same when they name the same build, so a caller can
    # compare them without reaching for the strings inside.
    test "sources naming the same build are equal and hash alike" do
      one = ::ScData::Source.new(version: "4.9.0-live.1", environment: "live")
      same = ::ScData::Source.new(version: "4.9.0-live.1", environment: "live")
      other = ::ScData::Source.new(version: "4.9.0-live.1", environment: "ptu")

      assert_equal one, same
      assert_equal one.hash, same.hash
      refute_equal one, other
      assert_equal 1, [one, same].uniq.size
    end

    test "#to_s names the build and the environment it came from" do
      source = ::ScData::Source.new(version: "4.9.0-live.1", environment: "live")

      assert_equal "4.9.0-live.1 (live)", source.to_s
    end
  end
end
