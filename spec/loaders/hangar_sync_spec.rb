# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe HangarSync do
  let(:loader) { ::Rsi::ModelsLoader.new }
  let(:user) { create(:user) }
  let(:input) { JSON.parse(Rails.root.join("spec/fixtures/sync/rsi_hangar.json").read) }
  let(:matrix_response_stub) { File.read("spec/fixtures/rsi/matrix.json") }
  let(:pledge_store_data) { JSON.parse(File.read("spec/fixtures/rsi/pledge_store.json")) }

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

    loader.all

    load Rails.root.join("db/seeds/01_manual_models.rb")
  end

  after do
    Timecop.return
  end

  context "with existing vehicles" do
    let(:andromeda_model) { Model.find_by!(slug: "constellation-andromeda") }
    let(:corsair_model) { Model.find_by!(slug: "corsair") }
    let(:javelin_model) { Model.find_by!(slug: "javelin") }

    let!(:andromeda_ship) do
      create(:vehicle, user: user, model: andromeda_model, name: "USS Troi", wanted: false, public: true)
    end
    let!(:pirate_ship) do
      create(:vehicle, user: user, model: corsair_model, wanted: false)
    end
    let!(:jav_ship) do
      create(:vehicle, user: user, model: javelin_model, wanted: false, public: true, flagship: true)
    end

    it "syncs all data" do
      Timecop.freeze(1.minute.from_now)

      result = ::HangarSync.new(input).run(user.id)

      expect(result[:found_vehicles]).to contain_exactly(andromeda_ship.id, pirate_ship.id)
      expect(result[:moved_vehicles_to_wanted]).to eq([jav_ship.id])
      expect(result[:imported_vehicles].size).to eq(47)
      expect(result[:missing_components]).to eq([])
      expect(result[:missing_models]).to eq([])
      expect(result[:imported_components]).to eq([])
      expect(result[:found_components]).to eq([])
      expect(result[:missing_component_vehicles]).to eq([])
      expect(result[:imported_upgrades]).to eq([])
      expect(result[:found_upgrades]).to eq([])

      expect(andromeda_ship.reload.name).to eq("USS Troi")
      expect(pirate_ship.reload.name).to eq("Enterprise")
    end
  end
end
