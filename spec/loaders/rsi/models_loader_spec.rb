# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

describe Rsi::ModelsLoader do
  let(:loader) { ::Rsi::ModelsLoader.new }
  let(:matrix_response_stub) { File.read("spec/fixtures/rsi/matrix.json") }
  let(:pledge_store_data) { JSON.parse(File.read("spec/fixtures/rsi/pledge_store.json")) }
  let(:polaris) do
    create(
      :model,
      name: "Polaris",
      length: 20,
      sc_identifier: "rsi_polaris",
      rsi_id: 116,
      rsi_chassis_id: 4
    )
  end

  before do
    Timecop.freeze("2017-01-01 14:00:00")

    stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/ship-matrix/index.*})
      .to_return(status: 200, body: matrix_response_stub)

    stub_request(:post, %r{\Ahttps://robertsspaceindustries.com/graphql})
      .to_return do |request|
        body = JSON.parse(request.body)
        chassis_id = body.first.dig("variables", "query", "ships", "chassisId", 0)
        resources = pledge_store_data[chassis_id.to_s] || []
        {status: 200, body: [{data: {store: {search: {resources: resources}}}}].to_json, headers: {"Content-Type" => "application/json"}}
      end
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

    loader.all

    expectations = {
      models: initial_model_count + 211,
      hardpoints: initial_hardpoint_count + 9104,
      components: initial_component_count,
      paints: initial_paint_count + 15,
      manufacturers: initial_manufacturer_count + 18
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

  it "#one" do
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
      manufacturers: initial_manufacturer_count + 1
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

  it "#updates only when needed" do
    loader.one(7)

    model = Model.find_by(name: "300i")

    Timecop.travel(1.day)

    loader.one(model.rsi_id)

    model.reload

    expect(model.updated_at.day).not_to eq(Time.zone.now.day)
    assert_in_delta(27.0, model.length.to_f)
  end

  it "#updates production status only when time_modified changes" do
    loader.one(7)

    model = Model.find_by(name: "300i")

    assert_equal("flight-ready", model.production_status)

    model.update(production_status: "in-concept")

    Timecop.travel(1.day)

    loader.one(7)

    model.reload

    expect("in-concept").to eq(model.production_status)
  end

  it "#overides present data" do
    assert_in_delta(20.0, polaris.length.to_f)
    assert_equal(polaris.last_updated_at.utc.iso8601, polaris.created_at.utc.iso8601)

    Timecop.travel(1.day)

    loader.one(116)

    polaris.reload

    assert_in_delta(166.0, polaris.length.to_f)
    assert_equal("2024-12-05T19:00:50Z", polaris.last_updated_at.utc.iso8601)
  end
end
