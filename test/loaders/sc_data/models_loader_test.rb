# frozen_string_literal: true

require "test_helper"
require_relative "../../support/hangar_import_fixtures"

module ScData
  module Loader
    class ModelsLoaderTest < ActiveSupport::TestCase
      include HangarImportFixtures

      setup do
        clean_loader_tables
      end

      test "#one loads data from game files" do
        loader = ::ScData::Loader::ModelsLoader.new
        manufacturer = create(:manufacturer, name: "Roberts Space Industries", slug: "rsi", code: "RSI")
        model = create(:model, name: "Constellation Andromeda", manufacturer: manufacturer, in_game: true)

        assert_difference -> { Hardpoint.where(parent: model).count }, 95 do
          loader.one(model)
        end
      end

      test "#load_model persists the parsed cross section signature" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "Cross Section Test", in_game: true)
        cross_section = {"x" => 12.5, "y" => 34.0, "z" => 56.25}

        loader.stubs(:load_model_data).returns(
          {"mass" => 1000.0, "loadout" => [], "signature_cross_section" => cross_section}
        )

        loader.load_model(model)

        assert_equal cross_section, model.reload.signature_cross_section
      end

      test "#load_model persists the parsed ground speeds" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "Ground Speed Test", in_game: true)

        loader.stubs(:load_model_data).returns(
          {
            "mass" => 1000.0,
            "loadout" => [],
            "speeds" => {
              "max" => 24.0,
              "reverse" => 12.0,
              "acceleration" => 8.0,
              "decceleration" => 12.0
            }
          }
        )

        loader.load_model(model)
        model.reload

        assert_equal 24.0, model.ground_max_speed.to_f
        assert_equal 12.0, model.ground_reverse_speed.to_f
        assert_equal 8.0, model.ground_acceleration.to_f
        assert_equal 12.0, model.ground_decceleration.to_f
      end

      test "#load_model keeps the ground speeds a vehicle does not declare" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "Wheel Cap Test", in_game: true, ground_reverse_speed: 9.0)

        loader.stubs(:load_model_data).returns(
          {"mass" => 1000.0, "loadout" => [], "speeds" => {"max" => 36.0}}
        )

        loader.load_model(model)
        model.reload

        assert_equal 36.0, model.ground_max_speed.to_f
        assert_equal 9.0, model.ground_reverse_speed.to_f
      end
    end
  end
end
