# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"
require_relative "../../support/hangar_import_fixtures"

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
          models: initial_model_count + 211,
          hardpoints: initial_hardpoint_count + 9104,
          components: initial_component_count,
          paints: initial_paint_count + 15,
          manufacturers: initial_manufacturer_count + 18
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
          hardpoints: initial_hardpoint_count + 34,
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

    test "#overrides present data" do
      polaris = create(:model, name: "Polaris", length: 20, rsi_id: 116, rsi_chassis_id: 4)

      assert_in_delta 20.0, polaris.length.to_f
      assert_equal polaris.created_at.utc.iso8601, polaris.last_updated_at.utc.iso8601

      Timecop.travel(1.day)

      @loader.one(116)

      polaris.reload

      assert_in_delta 166.0, polaris.length.to_f
      assert_equal "2024-12-05T19:00:50Z", polaris.last_updated_at.utc.iso8601
    end
  end
end
