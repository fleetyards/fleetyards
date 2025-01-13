# frozen_string_literal: true

require "test_helper"

class Rsi::ModelsLoaderTest < ActiveSupport::TestCase
  let(:pledge_response_stub) { File.read("test/fixtures/rsi/300i_pledge_page.html") }
  let(:matrix_response_stub) { File.read("test/fixtures/rsi/matrix.json") }

  let(:loader) { ::Rsi::ModelsLoader.new }

  before do
    Timecop.freeze("2017-01-01 14:00:00")

    stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/pledge/ships/.*/.*})
      .to_return(status: 200, body: pledge_response_stub)

    stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/ship-matrix/index.*})
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

    loader.all

    expectations = {
      models: initial_model_count + 200,
      hardpoints: initial_hardpoint_count + 7110,
      components: initial_component_count,
      paints: initial_paint_count + 15,
      manufacturers: initial_manufacturer_count + 12
    }

    assert_equal(
      expectations,
      models: Model.count,
      hardpoints: Hardpoint.count,
      components: Component.count,
      paints: ModelPaint.count,
      manufacturers: Manufacturer.count
    )

    assert_equal(Model.find_by(slug: "300i").rsi_chassis_id, Model.find_by(slug: "315p").rsi_chassis_id)
  end

  test "#one" do
    initial_model_count = Model.count
    initial_hardpoint_count = Hardpoint.count
    initial_component_count = Component.count
    initial_paint_count = ModelPaint.count
    initial_manufacturer_count = Manufacturer.count

    loader.one(7)

    expectations = {
      models: initial_model_count + 1,
      hardpoints: initial_hardpoint_count + 34,
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

  test "#updates only when needed" do
    loader.one(7)

    model = Model.find_by(name: "300i")

    Timecop.travel(1.day)

    loader.one(model.rsi_id)
    model.reload

    assert_not_equal(model.updated_at.day, Time.zone.now.day)
    assert_in_delta(27.0, model.length.to_f)
  end

  test "#updates production status only when time_modified changes" do
    loader.one(7)

    model = Model.find_by(name: "300i")

    assert_equal("flight-ready", model.production_status)

    model.update(production_status: "in-concept")

    Timecop.travel(1.day)

    loader.one(model.rsi_id)
    model.reload

    assert_equal("in-concept", model.production_status)
  end

  test "#overides present data" do
    model_polaris = Model.create(
      name: "Polaris",
      rsi_id: 116,
      length: 20.0
    )

    assert_in_delta(20.0, model_polaris.length.to_f)
    assert_equal(model_polaris.last_updated_at.utc.iso8601, model_polaris.created_at.utc.iso8601)

    Timecop.travel(1.day)

    loader.one(116)

    model_polaris.reload

    assert_in_delta(166.0, model_polaris.length.to_f)
    assert_equal("2024-12-05T19:00:50Z", model_polaris.last_updated_at.utc.iso8601)
  end
end
