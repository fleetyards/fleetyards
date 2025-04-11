# frozen_string_literal: true

require "test_helper"

class Rsi::HardpointsLoaderTest < ActiveSupport::TestCase
  let(:matrix_response_stub) { File.read("test/fixtures/rsi/matrix.json") }

  let(:andromeda) { models :andromeda }
  let(:loader) { ::Rsi::HardpointsLoader.new }

  before do
    Timecop.freeze("2017-01-01 14:00:00")

    stub_request(:get, "https://robertsspaceindustries.com/ship-matrix/index?#{Time.zone.now.to_i}")
      .to_return(status: 200, body: matrix_response_stub)
  end

  after do
    Timecop.return
  end

  test "#all" do
    initial_model_count = Model.count
    initial_hardpoint_count = Hardpoint.count
    initial_component_count = Component.count
    initial_paint_count = ModelPaint.count
    initial_manufacturer_count = Manufacturer.count

    loader.all(andromeda)

    expectations = {
      models: initial_model_count + 0,
      hardpoints: initial_hardpoint_count + 107,
      components: initial_component_count,
      paints: initial_paint_count,
      manufacturers: initial_manufacturer_count + 0
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
