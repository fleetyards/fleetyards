# frozen_string_literal: true

require "test_helper"
require_relative "../../support/legacy_manufacturer_duplicates"

module Manufacturers
  class DeduplicatorTest < ActiveSupport::TestCase
    include LegacyManufacturerDuplicates

    # The service looks for collisions across the whole table, so anything left
    # behind by another run would decide the winners instead of the fixtures.
    #
    # The duplicates it cleans up are ones the database now refuses to hold, so
    # the index comes off for the duration of each test.
    setup do
      Manufacturer.delete_all
      allow_duplicate_manufacturer_slugs
    end

    test "#call renames a record the export mislabelled" do
      manufacturer = create(:manufacturer, code: "MXOX", name: "Aegis Dynamics")

      result = ::Manufacturers::Deduplicator.new(corrections: {"MXOX" => "maxOx"}).call

      assert_equal "maxOx", manufacturer.reload.name
      assert_equal ["MXOX"], result.renamed
    end

    test "#call leaves a name that is already correct" do
      create(:manufacturer, code: "MXOX", name: "maxOx")

      result = ::Manufacturers::Deduplicator.new(corrections: {"MXOX" => "maxOx"}).call

      assert_empty result.renamed
    end

    test "#call drops a placeholder record nothing points at" do
      create(:manufacturer, code: "TRAS", name: "Aegis Dynamics")

      result = ::Manufacturers::Deduplicator.new(dropped_codes: ["TRAS"]).call

      assert_nil Manufacturer.find_by(code: "TRAS")
      assert_equal ["TRAS"], result.dropped
    end

    # A placeholder that somehow acquired items is one somebody is using, and
    # deleting it would nullify their manufacturer.
    test "#call keeps a record marked for dropping when something points at it" do
      manufacturer = create(:manufacturer, code: "TRAS", name: "Aegis Dynamics")
      create(:component, manufacturer:)

      result = ::Manufacturers::Deduplicator.new(dropped_codes: ["TRAS"]).call

      assert_equal manufacturer, Manufacturer.find_by(code: "TRAS")
      assert_empty result.dropped
    end

    test "#call merges two manufacturers sharing a name onto one row" do
      keep = create(:manufacturer, name: "Gatac Manufacture", code: "GAMA", rsi_id: 93)
      drop = create(:manufacturer, name: "Gatac Manufacture", code: "GAM", rsi_id: nil)

      ::Manufacturers::Deduplicator.new.call

      assert_equal [keep.id], Manufacturer.where(name: "Gatac Manufacture").ids
      assert_nil Manufacturer.find_by(id: drop.id)
    end

    test "#call repoints every association of a merged manufacturer" do
      keep = create(:manufacturer, name: "Klaus & Werner", code: "KLA", rsi_id: 1)
      drop = create(:manufacturer, name: "Klaus & Werner", code: nil)

      component = create(:component, manufacturer: drop)
      equipment = create(:equipment, manufacturer: drop)
      equipment_build = create(:equipment_build, manufacturer: drop)
      model = create(:model, manufacturer: drop)

      ::Manufacturers::Deduplicator.new.call

      assert_equal keep, component.reload.manufacturer
      assert_equal keep, equipment.reload.manufacturer
      assert_equal keep, equipment_build.reload.manufacturer
      assert_equal keep, model.reload.manufacturer
    end

    # What an admin curated cannot be rebuilt from the export, so it decides the
    # winner before row counts do.
    test "#call keeps the curated row even when the other carries more records" do
      curated = create(:manufacturer, name: "Sakura Sun", code: "SASU", rsi_id: 7)
      busier = create(:manufacturer, name: "Sakura Sun", code: "ROO", rsi_id: nil)
      create_list(:component, 3, manufacturer: busier)

      ::Manufacturers::Deduplicator.new.call

      assert_equal [curated.id], Manufacturer.where(name: "Sakura Sun").ids
      assert_equal 3, curated.reload.components.count
    end

    test "#call prefers the row carrying more records when neither is curated" do
      lean = create(:manufacturer, name: "Sakura Sun", code: "ROO", rsi_id: nil)
      busier = create(:manufacturer, name: "Sakura Sun", code: "SASU", rsi_id: nil)
      create_list(:component, 2, manufacturer: busier)

      ::Manufacturers::Deduplicator.new.call

      assert_equal [busier.id], Manufacturer.where(name: "Sakura Sun").ids
      assert_nil Manufacturer.find_by(id: lean.id)
    end

    test "#call collapses a group of four onto a single row" do
      keep = create(:manufacturer, name: "Aegis Dynamics", code: "AEGS", rsi_id: 12)
      3.times { |index| create(:manufacturer, name: "Aegis Dynamics", code: "DUP#{index}") }

      ::Manufacturers::Deduplicator.new.call

      assert_equal [keep.id], Manufacturer.where(name: "Aegis Dynamics").ids
    end

    # Eleven of the pairs in the table are this kind rather than an exact repeat,
    # and grouping by name would walk straight past them.
    test "#call merges rows whose names differ only by case" do
      keep = create(:manufacturer, name: "Gyson Inc.", rsi_id: 4)
      drop = create(:manufacturer, name: "GYSON INC")
      create(:component, manufacturer: drop)

      ::Manufacturers::Deduplicator.new.call

      assert_equal [keep.id], Manufacturer.where(slug: keep.slug).ids
      assert_equal 1, keep.reload.components.count
    end

    test "#call merges rows whose names differ only by trailing space" do
      keep = create(:manufacturer, name: "Basilisk ", rsi_id: 5)
      drop = create(:manufacturer, name: "Basilisk")

      ::Manufacturers::Deduplicator.new.call

      assert_nil Manufacturer.find_by(id: drop.id)
      assert_equal keep.id, Manufacturer.find_by(slug: "basilisk").id
    end

    # The curated row wins, and it is not always the one spelled properly.
    test "#call trims the surviving name" do
      create(:manufacturer, name: "Juno Starwerk ", rsi_id: 6)
      create(:manufacturer, name: "Juno Starwerk")

      ::Manufacturers::Deduplicator.new.call

      assert_equal "Juno Starwerk", Manufacturer.find_by(slug: "juno-starwerk").name
    end

    test "#call leaves manufacturers with distinct names alone" do
      create(:manufacturer, name: "Aegis Dynamics", code: "AEGS")
      create(:manufacturer, name: "maxOx", code: "MXOX")

      result = ::Manufacturers::Deduplicator.new.call

      assert_equal 2, Manufacturer.where(name: ["Aegis Dynamics", "maxOx"]).count
      assert_empty result.merged
    end

    # Corrections run first on purpose: renaming MXOX out of the Aegis group is
    # what stops the merge folding a different manufacturer into it.
    test "#call renames before merging so a corrected row is not merged away" do
      aegis = create(:manufacturer, name: "Aegis Dynamics", code: "AEGS", rsi_id: 12)
      maxox = create(:manufacturer, name: "Aegis Dynamics", code: "MXOX")
      create_list(:component, 2, manufacturer: maxox)

      ::Manufacturers::Deduplicator.new(corrections: {"MXOX" => "maxOx"}).call

      assert_equal "maxOx", maxox.reload.name
      assert_equal 2, maxox.components.count
      assert_equal [aegis.id], Manufacturer.where(name: "Aegis Dynamics").ids
    end

    # The merge repoints only the tables it is told about, and `dependent:
    # :nullify` on an association nobody declared does nothing -- so a table
    # added later would lose its manufacturer without a word. This is the guard
    # that turns that into a failing test.
    test "ASSOCIATED_MODELS covers every table referencing manufacturer_id" do
      referencing = Manufacturer.connection.tables.select do |table|
        Manufacturer.connection.columns(table).any? { |column| column.name == "manufacturer_id" }
      end

      assert_equal referencing.sort,
        ::Manufacturers::Deduplicator::ASSOCIATED_MODELS.map(&:table_name).sort
    end

    # Nothing here is undoable once committed, and the phases feed each other, so
    # a failure partway through would leave some names corrected, some
    # placeholders gone and some collisions still standing -- a worse table to
    # recover from than the one we started with.
    test "#call undoes the earlier phases when a later one fails" do
      renamed = create(:manufacturer, code: "MXOX", name: "Aegis Dynamics")
      placeholder = create(:manufacturer, code: "TRAS", name: "Nothing points here")

      deduplicator = FailingMerge.new(
        corrections: {"MXOX" => "maxOx"},
        dropped_codes: ["TRAS"]
      )

      assert_raises(FailingMerge::Boom) { deduplicator.call }

      assert_equal "Aegis Dynamics", renamed.reload.name
      assert_equal placeholder, Manufacturer.find_by(code: "TRAS")
    end

    # Overriding the last phase is the only way in: the merge is where a real
    # failure would land, since it is the phase that destroys rows.
    class FailingMerge < ::Manufacturers::Deduplicator
      Boom = Class.new(StandardError)

      private def merge_collisions
        raise Boom
      end
    end

    # The report has to be reviewable on production before anything is
    # destroyed, so it must leave the table exactly as it found it.
    test "#plan reports the merge and rolls it back" do
      keep = create(:manufacturer, name: "Gatac Manufacture", code: "GAMA", rsi_id: 93)
      drop = create(:manufacturer, name: "Gatac Manufacture", code: "GAM")
      component = create(:component, manufacturer: drop)

      plan = nil

      assert_no_difference -> { Manufacturer.count } do
        plan = ::Manufacturers::Deduplicator.new.plan
      end

      assert_equal 2, plan[:before]
      assert_equal 1, plan[:after]
      assert_equal ["gatac-manufacture"], plan[:merged]
      assert_equal drop, component.reload.manufacturer
      assert_equal keep, Manufacturer.find(keep.id)
    end

    test "#plan reports a rename without applying it" do
      manufacturer = create(:manufacturer, code: "MXOX", name: "Aegis Dynamics")

      plan = ::Manufacturers::Deduplicator.new(corrections: {"MXOX" => "maxOx"}).plan

      assert_equal ["MXOX"], plan[:renamed]
      assert_equal "Aegis Dynamics", manufacturer.reload.name
    end

    # Renaming MXOX takes it out of the Aegis group before the merge looks, so a
    # plan that read the table as it stands would report a merge that never
    # happens. Running it for real and rolling back is what keeps it honest.
    test "#plan accounts for the renames when reporting merges" do
      create(:manufacturer, name: "Aegis Dynamics", code: "AEGS", rsi_id: 12)
      create(:manufacturer, name: "Aegis Dynamics", code: "MXOX")

      plan = ::Manufacturers::Deduplicator.new(corrections: {"MXOX" => "maxOx"}).plan

      assert_equal ["MXOX"], plan[:renamed]
      assert_empty plan[:merged]
      assert_equal 2, plan[:after]
    end

    test "#plan reports a record it would refuse to drop" do
      manufacturer = create(:manufacturer, code: "TRAS", name: "Aegis Dynamics")
      create(:component, manufacturer:)

      plan = ::Manufacturers::Deduplicator.new(dropped_codes: ["TRAS"]).plan

      assert_empty plan[:dropped]
      # Two, not one: the component's build carries the manufacturer as well,
      # which is exactly why ComponentBuild is in ASSOCIATED_MODELS.
      assert_includes plan[:log].join("\n"), "2 records still point at it"
    end

    test "#plan reports no record left without a manufacturer" do
      keep = create(:manufacturer, name: "Sakura Sun", code: "SASU", rsi_id: 7)
      drop = create(:manufacturer, name: "Sakura Sun", code: "ROO")
      create(:component, manufacturer: drop)
      create(:equipment, manufacturer: drop)

      plan = ::Manufacturers::Deduplicator.new.plan

      assert_equal 0, plan[:orphaned]
      assert_equal [keep.id], Manufacturer.where(slug: "sakura-sun").ids - [drop.id]
    end
  end
end
