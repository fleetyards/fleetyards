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
  end
end
