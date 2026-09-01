# frozen_string_literal: true

require "test_helper"
require_relative "../../support/legacy_manufacturer_duplicates"

module Maintenance
  class DedupeManufacturersTaskTest < ActiveSupport::TestCase
    include LegacyManufacturerDuplicates

    # The duplicates the task cleans up are ones the database now refuses to
    # hold, so the index comes off for the duration of each test.
    setup do
      Manufacturer.delete_all
      allow_duplicate_manufacturer_slugs
    end

    # An accidental run has to report rather than destroy, so the safe mode is
    # the one you get by not choosing.
    test "dry_run is on unless it is turned off" do
      assert_predicate ::Maintenance::DedupeManufacturersTask.new, :dry_run
    end

    test "#process leaves every row in place on a dry run" do
      create(:manufacturer, name: "Gatac Manufacture", code: "GAMA", rsi_id: 93)
      create(:manufacturer, name: "Gatac Manufacture", code: "GAM")

      assert_no_difference -> { Manufacturer.count } do
        run_task(dry_run: true)
      end
    end

    test "#process reports what it would do on a dry run" do
      create(:manufacturer, name: "Gatac Manufacture", code: "GAMA", rsi_id: 93)
      create(:manufacturer, name: "Gatac Manufacture", code: "GAM")

      output = run_task(dry_run: true)

      assert_includes output, "gatac-manufacture"
      assert_includes output, "manufacturers: 2 -> 1"
      assert_includes output, "dry run"
    end

    test "#process merges the duplicates when the dry run is turned off" do
      keep = create(:manufacturer, name: "Gatac Manufacture", code: "GAMA", rsi_id: 93)
      drop = create(:manufacturer, name: "Gatac Manufacture", code: "GAM")
      component = create(:component, manufacturer: drop)

      run_task(dry_run: false)

      assert_equal [keep.id], Manufacturer.where(name: "Gatac Manufacture").ids
      assert_equal keep, component.reload.manufacturer
    end

    test "#process corrects the names the export mislabelled" do
      create(:manufacturer, name: "Aegis Dynamics", code: "AEGS", rsi_id: 12)
      mislabelled = create(:manufacturer, name: "Aegis Dynamics", code: "MXOX")

      run_task(dry_run: false)

      assert_equal "maxOx", mislabelled.reload.name
      assert_equal ["AEGS"], Manufacturer.where(name: "Aegis Dynamics").pluck(:code)
    end

    test "#process drops the placeholder records" do
      create(:manufacturer, name: "Aegis Dynamics", code: "TRAS")

      run_task(dry_run: false)

      assert_nil Manufacturer.find_by(code: "TRAS")
    end

    test "#process merges the row the export filed under a second code" do
      keep = create(:manufacturer, name: "MISC", code: "MISC", rsi_id: 4, sc_ref: nil)
      drop = create(:manufacturer, name: "Musashi Industrial & Starflight Concern",
        code: "MIS", sc_ref: "b28a5c61")
      component = create(:component, manufacturer: drop)

      run_task(dry_run: false)

      assert_nil Manufacturer.find_by(code: "MIS")
      assert_equal keep, component.reload.manufacturer
      assert_equal "b28a5c61", keep.reload.sc_ref
    end

    test "#process reports the alias merge on a dry run" do
      create(:manufacturer, name: "MISC", code: "MISC", rsi_id: 4)
      create(:manufacturer, name: "Musashi Industrial & Starflight Concern", code: "MIS")

      output = run_task(dry_run: true)

      assert_includes output, "MIS -> MISC"
      assert_includes output, "manufacturers: 2 -> 1"
      assert_includes output, "dry run"
    end

    # The corrections have to match the overrides the parser applies, or a fresh
    # import and a cleaned table would disagree about what a code is called.
    test "the corrections agree with the shipped parser overrides" do
      overrides = ::ScData::Parser::ManufacturersParser.overrides

      overrides.each do |code, entry|
        next if entry["name"].blank?

        assert_equal entry["name"], ::Maintenance::DedupeManufacturersTask::CORRECTIONS[code],
          "#{code} is named #{entry["name"].inspect} by the parser overrides"
      end

      dropped = overrides.select { |_, entry| entry["skip"] }.keys

      assert_equal dropped.sort, ::Maintenance::DedupeManufacturersTask::DROPPED_CODES.sort
    end

    private def run_task(dry_run:)
      task = ::Maintenance::DedupeManufacturersTask.new
      task.dry_run = dry_run

      capture_io { task.process }.first
    end
  end
end
