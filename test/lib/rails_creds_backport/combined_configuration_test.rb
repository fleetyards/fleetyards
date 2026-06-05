# frozen_string_literal: true

require "test_helper"

module RailsCredsBackport
  class CombinedConfigurationTest < ActiveSupport::TestCase
    setup do
      @backend_a = mock("backend_a")
      @backend_a.stubs(:option).returns(nil)
      @backend_a.stubs(:reload)

      @backend_b = mock("backend_b")
      @backend_b.stubs(:option).returns(nil)
      @backend_b.stubs(:reload)

      @combined = CombinedConfiguration.new(@backend_a, @backend_b)
    end

    test "#require returns the value from the first backend that has it" do
      @backend_a.stubs(:option).with(:key).returns("from_a")
      assert_equal "from_a", @combined.require(:key)
    end

    test "#require falls through to the second backend" do
      @backend_a.stubs(:option).with(:key).returns(nil)
      @backend_b.stubs(:option).with(:key).returns("from_b")
      assert_equal "from_b", @combined.require(:key)
    end

    test "#require raises KeyError when no backend has the key" do
      assert_raises(KeyError) { @combined.require(:missing) }
    end

    test "#require returns false values without raising" do
      @backend_a.stubs(:option).with(:flag).returns(false)
      assert_equal false, @combined.require(:flag)
    end

    test "#option returns nil when no backend has the key" do
      assert_nil @combined.option(:missing)
    end

    test "#option returns the default when no backend has the key" do
      assert_equal "fallback", @combined.option(:missing, default: "fallback")
    end

    test "#option calls a default proc" do
      assert_equal "computed", @combined.option(:missing, default: -> { "computed" })
    end

    test "#option returns false values without triggering default" do
      @backend_a.stubs(:option).with(:flag).returns(false)
      assert_equal false, @combined.option(:flag, default: "nope")
    end

    test "#reload reloads all backends" do
      @backend_a.expects(:reload)
      @backend_b.expects(:reload)
      @combined.reload
    end
  end
end
