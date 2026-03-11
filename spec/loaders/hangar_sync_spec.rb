# frozen_string_literal: true

require "rails_helper"

RSpec.describe HangarSync do
  fixtures :users, :vehicles, :models, :manufacturers

  let(:loader) { ::Rsi::ModelsLoader.new }
  let(:user) { users(:troi) }
  let(:input) { JSON.parse(Rails.root.join("spec/fixtures/sync/rsi_hangar.json").read) }
  let(:andromeda_ship) { vehicles(:andromeda_troi) }
  let(:pirate_ship) { vehicles(:pirate_troi) }

  before do
    Timecop.freeze("2017-01-01 14:00:00")
    VCR.use_cassette("rsi_models_loader_all") do
      loader.all
    end
  end

  after do
    Timecop.return
  end

  it "syncs all data" do
    result = ::HangarSync.new(input).run(user.id)

    expect(result[:found_vehicles]).to eq(["2a96935a-c63d-561f-9c57-2bfc2f94d863", "e1ecd6c9-3d52-5fbb-8cee-1a2ddf12ab3e"])
    expect(result[:moved_vehicles_to_wanted]).to eq(["3d543e17-aefe-5392-973b-2c2806eb9aa6"])
    expect(result[:imported_vehicles].size).to eq(47)
    expect(result[:missing_components]).to eq([])
    expect(result[:missing_models]).to eq([])
    expect(result[:imported_components]).to eq([])
    expect(result[:found_components]).to eq([])
    expect(result[:missing_component_vehicles]).to eq([])
    expect(result[:imported_upgrades]).to eq([])
    expect(result[:found_upgrades]).to eq([])

    expect(andromeda_ship.reload.name).to eq("USS Troi")
    expect(pirate_ship.reload.name).to eq("Contorta")
  end
end
