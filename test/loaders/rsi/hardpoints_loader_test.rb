# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"
require_relative "../../support/hangar_import_fixtures"

module Rsi
  class HardpointsLoaderTest < ActiveSupport::TestCase
    include HangarImportFixtures

    setup do
      clean_loader_tables
      @andromeda = create(:model, name: "Constellation Andromeda", rsi_id: 45, rsi_chassis_id: 4)
      @loader = ::Rsi::HardpointsLoader.new
      @matrix_response_stub = File.read("spec/fixtures/rsi/matrix.json")

      Timecop.freeze("2017-01-01 14:00:00")

      stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/ship-matrix/index.*})
        .to_return(status: 200, body: @matrix_response_stub)
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

      @loader.all(@andromeda)

      assert_equal(
        {
          models: initial_model_count,
          hardpoints: initial_hardpoint_count + 107,
          components: initial_component_count,
          paints: initial_paint_count,
          manufacturers: initial_manufacturer_count
        },
        models: Model.count,
        hardpoints: Hardpoint.count,
        components: Component.count,
        paints: ModelPaint.count,
        manufacturers: Manufacturer.count
      )
    end
  end
end
