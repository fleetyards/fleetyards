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
    end
  end
end
