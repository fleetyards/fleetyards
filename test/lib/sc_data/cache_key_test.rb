# frozen_string_literal: true

require "test_helper"

module ScData
  class CacheKeyTest < ActiveSupport::TestCase
    LIVE = "4.10.1-live.1"
    PTU = "4.10.1-ptu.2"

    setup do
      Rails.configuration.stubs(:sc_data).returns({sources: {live: LIVE, ptu: PTU}, default: "live"})
    end

    test ".call names each source by the tree it is on" do
      stub_checksums("live" => "live-tree", "ptu" => "ptu-tree")

      result = ::ScData::CacheKey.call

      assert_equal "live-live-tree_ptu-ptu-tree", result.key
      assert_empty result.warnings
    end

    # A tree pushed before the parser wrote a checksum. Keying on its version is
    # exactly what the key did before any of this.
    test ".call falls back to the version for a tree that states no checksum" do
      stub_checksums("live" => "live-tree", "ptu" => nil)

      assert_equal "live-live-tree_ptu-#{PTU}", ::ScData::CacheKey.call.key
    end

    # The step this replaced was a local YAML read that could not fail, and it
    # gates every `ruby-tests` run -- including ones whose cache would have hit
    # and needed no network at all. A blip must cost a stale cache entry, not a
    # red run on every open pull request.
    test ".call falls back to the version when the bucket cannot be read" do
      ::ScData::ParsedStore.any_instance.stubs(:remote_checksum).raises(Aws::S3::Errors::ServiceError.new(nil, "down"))

      result = ::ScData::CacheKey.call

      assert_equal "live-#{LIVE}_ptu-#{PTU}", result.key
      assert_equal 2, result.warnings.size
      assert_match(/Could not read the live tree/, result.warnings.first)
    end

    test ".call keeps the sources that answer when one does not" do
      ::ScData::ParsedStore.any_instance.stubs(:remote_checksum).returns("live-tree").then
        .raises(Aws::S3::Errors::ServiceError.new(nil, "down"))

      assert_equal "live-live-tree_ptu-#{PTU}", ::ScData::CacheKey.call.key
    end

    test ".call skips a source carrying no version" do
      Rails.configuration.stubs(:sc_data).returns({sources: {live: LIVE, ptu: nil}, default: "live"})
      stub_checksums("live" => "live-tree")

      assert_equal "live-live-tree", ::ScData::CacheKey.call.key
    end

    # The caller aborts on this rather than emitting a bare `key=`, which would
    # collapse every run onto one cache entry whatever the trees are.
    test ".call is empty when no source carries a version" do
      Rails.configuration.stubs(:sc_data).returns({sources: {live: nil}, default: "live"})

      assert_predicate ::ScData::CacheKey.call, :empty?
    end

    private def stub_checksums(by_environment)
      by_environment.each do |environment, checksum|
        ::ScData::ParsedStore.stubs(:new).with(environment, settings: nil)
          .returns(stub(remote_checksum: checksum))
      end
    end
  end
end
