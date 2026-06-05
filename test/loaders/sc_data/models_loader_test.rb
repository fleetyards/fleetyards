# frozen_string_literal: true

require "test_helper"

module ScData
  module Loader
    class ModelsLoaderTest < ActiveSupport::TestCase
      test "#one loads data from game files" do
        loader = ::ScData::Loader::ModelsLoader.new
        manufacturer = create(:manufacturer, name: "Roberts Space Industries", slug: "rsi", code: "RSI")
        model = create(:model, name: "Constellation Andromeda", manufacturer: manufacturer, in_game: true)

        assert_difference -> { Hardpoint.where(parent: model).count }, 95 do
          loader.one(model)
        end
      end
    end
  end
end
