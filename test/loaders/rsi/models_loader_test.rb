# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"
require "support/hangar_import_fixtures"

module Rsi
  class ModelsLoaderTest < ActiveSupport::TestCase
    include HangarImportFixtures

    setup do
      clean_loader_tables
      @loader = ::Rsi::ModelsLoader.new
      @pledge_store_data = JSON.parse(File.read("test/fixtures/rsi/pledge_store.json"))

      Timecop.freeze("2017-01-01 14:00:00")
      stub_rsi_matrix_and_pledge_store(@pledge_store_data)
    end

    teardown do
      Timecop.return
    end

    test "#all" do
      initial_model_count = Model.count
      initial_hardpoint_count = Hardpoint.count
      initial_component_count = Component.count
      initial_paint_count = ModelPaint.count
      initial_manufacturer_count = Manufacturer.count

      @loader.all

      assert_equal(
        {
          models: initial_model_count + 240,
          hardpoints: initial_hardpoint_count + 4973,
          components: initial_component_count,
          paints: initial_paint_count + 10,
          manufacturers: initial_manufacturer_count + 19
        },
        models: Model.count,
        hardpoints: Hardpoint.count,
        components: Component.count,
        paints: ModelPaint.count,
        manufacturers: Manufacturer.count
      )

      assert_equal Model.find_by(slug: "orig-300i").rsi_chassis_id, Model.find_by(slug: "orig-315p").rsi_chassis_id
    end

    test "#one" do
      initial_model_count = Model.count
      initial_hardpoint_count = Hardpoint.count
      initial_component_count = Component.count
      initial_paint_count = ModelPaint.count
      initial_manufacturer_count = Manufacturer.count

      @loader.one(7)

      assert_equal(
        {
          models: initial_model_count + 1,
          hardpoints: initial_hardpoint_count + 17,
          components: initial_component_count,
          paints: initial_paint_count,
          manufacturers: initial_manufacturer_count + 1
        },
        models: Model.count,
        hardpoints: Hardpoint.count,
        components: Component.count,
        paints: ModelPaint.count,
        manufacturers: Manufacturer.count
      )
    end

    test "#updates only when needed" do
      @loader.one(7)

      model = Model.find_by(name: "300i")

      Timecop.travel(1.day)

      @loader.one(model.rsi_id)

      model.reload

      refute_equal Time.zone.now.day, model.updated_at.day
      assert_in_delta 27.0, model.length.to_f
    end

    test "#updates production status only when time_modified changes" do
      @loader.one(7)

      model = Model.find_by(name: "300i")

      assert_equal "flight-ready", model.production_status

      model.update(production_status: "in-concept")

      Timecop.travel(1.day)

      @loader.one(7)

      model.reload

      assert_equal "in-concept", model.production_status
    end

    # The matrix carries none of these four for almost every ship, and it used to
    # write `nil` over whatever the game-file loader had put there -- every run,
    # because the guard asked whether the *matrix* value was missing rather than
    # the live one.
    # The Gladius is one of the ships the matrix carries no manoeuvring figures
    # for. Today that is nearly every ship: 244 of 246 have `rsi_max_speed` NULL,
    # the matrix having stopped supplying these fields at some point -- this
    # fixture is an older snapshot where most ships still had them.
    test "#leaves a value alone when the matrix has nothing to put there" do
      @loader.one(60)

      model = Model.find_by(rsi_id: 60)
      model.update!(max_speed: 1210, pitch: 45, yaw: 40, roll: 120)

      Timecop.travel(1.day)

      @loader.one(60)

      model.reload

      assert_in_delta 1210.0, model.max_speed.to_f
      assert_in_delta 45.0, model.pitch.to_f
      assert_in_delta 40.0, model.yaw.to_f
      assert_in_delta 120.0, model.roll.to_f
    end

    # The matrix gives one crew figure for almost every ship now. Where a range
    # survives, the game files agree with its upper end.
    test "#takes the upper end of a crew range" do
      @loader.one(36)

      model = Model.find_by(rsi_id: 36)

      assert_equal 8, model.crew
      assert_equal 8, model.rsi_crew
    end

    test "#overrides present data" do
      polaris = create(:model, name: "Polaris", length: 20, rsi_id: 116, rsi_chassis_id: 4)

      assert_in_delta 20.0, polaris.length.to_f
      assert_equal polaris.created_at.utc.iso8601, polaris.last_updated_at.utc.iso8601

      Timecop.travel(1.day)

      @loader.one(116)

      polaris.reload

      assert_in_delta 181.0, polaris.length.to_f
      assert_equal "2026-06-25T15:03:13Z", polaris.last_updated_at.utc.iso8601
    end

    # The matrix capitalises its own vocabulary and the catalogue does not, and
    # copying it verbatim is how six ships ended up in a class nothing filters
    # on. `rsi_size` keeps the raw string -- it is what the change detector
    # compares against on the next run.
    test "#folds the matrix's capitalisation into the size the catalogue uses" do
      @loader.one(7)

      model = Model.find_by(rsi_id: 7)

      assert_equal "small", model.size
      assert_equal "Small", model.rsi_size
    end

    # A word we do not know fails the model's validation, and this update is
    # carrying every other field the matrix supplies -- so it is dropped on its
    # own rather than taking the ship's speeds and dimensions down with it.
    test "#leaves a size it does not recognise off the model" do
      data = JSON.parse(File.read("test/fixtures/rsi/matrix.json"))["data"].find { |ship| ship["id"] == 7 }

      @loader.send(:create_or_update_model, data.merge("size" => "Enormous"))

      model = Model.find_by(rsi_id: 7)

      assert_nil model.size
      assert_equal "Enormous", model.rsi_size
    end

    # The matrix carries no size for the ten largest ground vehicles -- the Ursa
    # family, the Lynx, the Storms, the Novas -- which are exactly the ones
    # 20260920110000 fills in. Writing that absence back would undo the backfill
    # on the next nightly run.
    test "#leaves a curated size alone when the matrix carries none" do
      create(:model, name: "Ursa", rsi_id: 139, rsi_chassis_id: 40, size: "vehicle")

      @loader.one(139)

      assert_equal "vehicle", Model.find_by(rsi_id: 139).size
    end

    # And it would not merely undo it: a vehicle on the ladder may not stop
    # being a vehicle, so the update carrying the blank would fail validation
    # and take the ship's dimensions and speeds down with it.
    test "#does not invalidate a vehicle that carries a ladder class" do
      create(:model, name: "Ursa", rsi_id: 139, rsi_chassis_id: 40, size: "vehicle", vehicle_size: "large")

      @loader.one(139)

      model = Model.find_by(rsi_id: 139)

      assert_equal "vehicle", model.size
      assert_equal "large", model.vehicle_size
    end

    # The manufacturer loader is the only thing that fills a manufacturer's
    # logo and its RSI metadata, and it used to be reached only for a model
    # whose manufacturer was unset -- so a sync over ships that all had one
    # never ran it.
    test "#syncs the manufacturer of a model that already has one" do
      manufacturer = create(:manufacturer, name: "Origin Jumpworks", code: "ORIG", rsi_id: nil, known_for: nil)
      create(:model, name: "300i", rsi_id: 7, rsi_chassis_id: 1, manufacturer: manufacturer)

      @loader.one(7)

      manufacturer.reload

      assert_equal 6, manufacturer.rsi_id
      assert_predicate manufacturer.known_for, :present?
    end

    test "#adopts a game-file model the matrix spells differently" do
      manufacturer = create(:manufacturer, name: "Anvil Aerospace", code: "ANVL", rsi_id: nil)
      model = create(:model, name: "F7CM Super HORNET Mk I", rsi_id: nil, manufacturer:, sc_key: "anvl_hornet_f7cm")

      assert_no_difference -> { Model.count } do
        @loader.one(15)
      end

      model.reload

      assert_equal 15, model.rsi_id
      assert_equal "F7C-M Super Hornet Mk I", model.name
    end

    test "#adopts a game-file model that still carries the manufacturer prefix" do
      manufacturer = create(:manufacturer, name: "Anvil Aerospace", code: "ANVL", rsi_id: nil)
      model = create(:model, name: "Anvil F7C-M Super Hornet Mk I", rsi_id: nil, manufacturer:)

      assert_no_difference -> { Model.count } do
        @loader.one(15)
      end

      assert_equal 15, model.reload.rsi_id
    end

    test "#adopts a game-file model created after the matrix entry last changed" do
      manufacturer = create(:manufacturer, name: "Anvil Aerospace", code: "ANVL", rsi_id: nil)
      model = create(:model, name: "F7CM Super Hornet Mk I", rsi_id: nil, manufacturer:,
        last_updated_at: Time.zone.parse("2026-07-01"), description: nil)

      @loader.one(15)
      model.reload

      assert_equal 15, model.rsi_id
      assert_equal "F7C-M Super Hornet Mk I", model.name
      assert_predicate model.description, :present?
    end

    test "#adopts a game-file model prefixed with the manufacturer code" do
      manufacturer = create(:manufacturer, name: "Roberts Space Industries", code: "RSI", rsi_id: nil)
      model = create(:model, name: "RSI Aurora MkI ES", rsi_id: nil, manufacturer:)

      assert_no_difference -> { Model.count } do
        @loader.one(1)
      end

      assert_equal 1, model.reload.rsi_id
    end

    test "#does not adopt a game-file model of another manufacturer" do
      other = create(:manufacturer, name: "Drake Interplanetary", code: "DRAK", rsi_id: nil)
      create(:manufacturer, name: "Anvil Aerospace", code: "ANVL", rsi_id: nil)
      model = create(:model, name: "F7CM Super Hornet Mk I", rsi_id: nil, manufacturer: other)

      assert_difference -> { Model.count }, 1 do
        @loader.one(15)
      end

      assert_nil model.reload.rsi_id
    end

    test "#does not adopt when two game-file models match" do
      manufacturer = create(:manufacturer, name: "Anvil Aerospace", code: "ANVL", rsi_id: nil)
      first = create(:model, name: "F7CM Super Hornet Mk I", rsi_id: nil, manufacturer:)
      second = create(:model, name: "F7C M Super Hornet Mk I", rsi_id: nil, manufacturer:)

      assert_difference -> { Model.count }, 1 do
        @loader.one(15)
      end

      assert_nil first.reload.rsi_id
      assert_nil second.reload.rsi_id
    end
  end
end
