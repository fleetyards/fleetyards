# frozen_string_literal: true

require "test_helper"

module ScData
  class CodeDigestTest < ActiveSupport::TestCase
    OLD = ::ScData::Source.new(environment: "live", version: "1.0.0-live.1")
    NEW = ::ScData::Source.new(environment: "live", version: "1.0.1-live.2")

    private def loaded(source, code_digest)
      ::Imports::ScData::AllImport.create!(version: source.version, aasm_state: "finished", finished_at: Time.current, code_digest:)
    end

    test ".relation is the same for two builds read by one code" do
      [OLD, NEW].each { |source| loaded(source, "a") }

      assert_equal "same", CodeDigest.relation(OLD, NEW)
    end

    test ".relation tells builds read by different code apart" do
      loaded(OLD, "a")
      loaded(NEW, "b")

      assert_equal "different", CodeDigest.relation(OLD, NEW)
    end

    test ".relation is unknown for a build loaded before the digest was kept" do
      loaded(OLD, nil)
      loaded(NEW, "b")

      assert_equal "unknown", CodeDigest.relation(OLD, NEW)
    end

    test "the parsers and the loaders have digests of their own" do
      assert_not_equal CodeDigest.parser, CodeDigest.loader
    end
  end
end
