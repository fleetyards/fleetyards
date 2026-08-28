# frozen_string_literal: true

require "test_helper"

# The write seam every loader goes through. Its value is telling the three
# outcomes apart -- `update!` reports a row it rewrote and a row it left alone
# identically, which is what made a badly landed build indistinguishable from a
# no-op in the logs.
module ScData
  module Loader
    class BaseLoaderApplyTest < ActiveSupport::TestCase
      setup do
        @loader = ::ScData::Loader::BaseLoader.new
      end

      test "#apply saves a new record and counts it as created" do
        commodity = @loader.apply(Commodity.new, {name: "Agricium", sc_key: "agricium"})

        assert_predicate commodity, :persisted?
        assert_equal "Agricium", commodity.name
        assert_equal({created: 1, updated: 0, unchanged: 0}, @loader.stats["Commodity"])
      end

      # `:without_build` here and below: `apply` writes the column, and a commodity
      # reads its build in preference to it, so a commodity with a build would
      # read as "Old" however the column moved. What is under test is the counting
      # seam, not the fact layering -- the loader always calls `apply_build`
      # alongside `apply`.
      test "#apply counts a record whose attributes moved as updated" do
        commodity = create(:commodity, :without_build, name: "Old")

        @loader.apply(commodity, {name: "New"})

        assert_equal "New", commodity.reload.name
        assert_equal({created: 0, updated: 1, unchanged: 0}, @loader.stats["Commodity"])
      end

      # The distinction the seam exists for: assigning the values a row already
      # holds is not a write, and a run of those should not read as one.
      test "#apply counts a record assigned its own values as unchanged" do
        commodity = create(:commodity, :without_build, name: "Same")

        @loader.apply(commodity, {name: "Same"})

        assert_equal({created: 0, updated: 0, unchanged: 1}, @loader.stats["Commodity"])
      end

      test "#apply returns the record so a caller can keep using it" do
        commodity = create(:commodity)

        assert_equal commodity, @loader.apply(commodity, {name: "Whatever"})
      end

      test "#apply raises rather than saving an invalid record" do
        assert_raises(ActiveRecord::RecordInvalid) { @loader.apply(Commodity.new, {name: nil}) }
      end

      # Counted separately from `apply` because it deliberately skips
      # validations and callbacks, so `changed?` is never consulted.
      # `hidden` rather than `in_game`: what is under test is the counting, and
      # `in_game?` reads a build row now rather than a column, so writing it
      # through `apply_columns` would prove nothing.
      test "#apply_columns writes the columns and counts an update" do
        model = create(:model, hidden: false)

        @loader.apply_columns(model, {hidden: true})

        assert_predicate model.reload, :hidden?
        assert_equal({created: 0, updated: 1, unchanged: 0}, @loader.stats["Model"])
      end

      test "counts are kept per model class" do
        @loader.apply(Commodity.new, {name: "Agricium", sc_key: "agricium"})
        @loader.apply(Commodity.new, {name: "Aluminium", sc_key: "aluminium"})
        @loader.apply_columns(create(:model), {hidden: true})

        assert_equal 2, @loader.stats["Commodity"][:created]
        assert_equal 1, @loader.stats["Model"][:updated]
      end

      test "#stats_summary says so plainly when a run wrote nothing" do
        assert_equal "nothing written", @loader.stats_summary
      end

      test "#stats_summary names each class and its counts" do
        @loader.apply(Commodity.new, {name: "Agricium", sc_key: "agricium"})

        assert_equal "Commodity created=1 updated=0 unchanged=0", @loader.stats_summary
      end
    end
  end
end
