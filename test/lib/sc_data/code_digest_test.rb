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

    test ".relation is unknown while a later load that wrote rows is unfinished" do
      [OLD, NEW].each { |source| loaded(source, "a") }
      ::Imports::ScData::AllImport.create!(version: NEW.version, aasm_state: "failed", tree_checksum: "tree", code_digest: "b")

      assert_equal "unknown", CodeDigest.relation(OLD, NEW)
    end

    test ".relation ignores a later load that failed before its loaders ran" do
      [OLD, NEW].each { |source| loaded(source, "a") }
      ::Imports::ScData::AllImport.create!(version: NEW.version, aasm_state: "failed")

      assert_equal "same", CodeDigest.relation(OLD, NEW)
    end

    test ".partial_load! leaves no one code to a build another code wrote into" do
      loaded(NEW, "a")
      CodeDigest.stubs(:current).returns("b")

      CodeDigest.partial_load!(NEW)

      assert_nil ::Imports::ScData::AllImport.last_finished_for(NEW).code_digest
    end

    test ".partial_load! keeps the code of a build the same code wrote into" do
      loaded(NEW, "a")
      CodeDigest.stubs(:current).returns("a")

      CodeDigest.partial_load!(NEW)

      assert_equal "a", ::Imports::ScData::AllImport.last_finished_for(NEW).code_digest
    end

    test ".of reads past comments and layout, and not past code" do
      digest = ->(source) {
        Dir.mktmpdir do |dir|
          FileUtils.mkdir_p("#{dir}/app/lib/sc_data/parser")
          File.write("#{dir}/app/lib/sc_data/parser/a.rb", source)
          ::Rails.stubs(:root).returns(Pathname(dir))
          CodeDigest.of("parser")
        ensure
          ::Rails.unstub(:root)
        end
      }

      assert_equal digest.call("a = 1\n"), digest.call("# why\na  =  1\n\n")
      assert_not_equal digest.call("a = 1\n"), digest.call("a = 2\n")
    end
  end
end
