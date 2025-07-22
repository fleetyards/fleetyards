# frozen_string_literal: true

require "rails_helper"

describe Rsi::HardpointsLoader do
  let(:andromeda) do
    create(
      :model,
      name: "Constellation Andromeda",
      sc_identifier: "rsi_constellation_andromeda",
      rsi_id: 45,
      rsi_chassis_id: 4
    )
  end
  let(:loader) { ::Rsi::HardpointsLoader.new }

  before do
    Timecop.freeze("2017-01-01 14:00:00")

    andromeda
  end

  after do
    Timecop.return
  end

  it "#all" do
    initial_model_count = Model.count
    initial_hardpoint_count = Hardpoint.count
    initial_component_count = Component.count
    initial_paint_count = ModelPaint.count
    initial_manufacturer_count = Manufacturer.count

    VCR.use_cassette("loaders/rsi_hardpoints_andromeda") do
      loader.all(andromeda)
    end

    expectations = {
      models: initial_model_count,
      hardpoints: initial_hardpoint_count + 106,
      components: initial_component_count,
      paints: initial_paint_count,
      manufacturers: initial_manufacturer_count
    }

    assert_equal(
      expectations,
      models: Model.count,
      hardpoints: Hardpoint.count,
      components: Component.count,
      paints: ModelPaint.count,
      manufacturers: Manufacturer.count
    )
  end
end
