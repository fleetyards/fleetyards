# frozen_string_literal: true

require "test_helper"

class HangarSyncTest < ActiveSupport::TestCase
  let(:loader) { ::Rsi::ModelsLoader.new }
  let(:user) { users :troi }
  let(:input) { JSON.parse(Rails.root.join("test/fixtures/sync/rsi_hangar.json").read) }
  let(:andromeda_ship) { vehicles :andromeda_troi }
  let(:pirate_ship) { vehicles :pirate_troi }

  before do
    VCR.use_cassette("rsi_models_loader_all") do
      loader.all
    end
  end

  test "syncs all data" do
    result = ::HangarSync.new(input).run(user.id)

    assert_equal(
      ["2a96935a-c63d-561f-9c57-2bfc2f94d863", "e1ecd6c9-3d52-5fbb-8cee-1a2ddf12ab3e"],
      result[:found_vehicles]
    )
    assert_equal(["3d543e17-aefe-5392-973b-2c2806eb9aa6"], result[:moved_vehicles_to_wanted])
    assert_equal(47, result[:imported_vehicles].size)
    assert(result[:missing_components].size.zero?)
    assert(result[:missing_models].size.zero?)
    assert(result[:imported_components].size.zero?)
    assert(result[:found_components].size.zero?)
    assert(result[:missing_component_vehicles].size.zero?)
    assert(result[:imported_upgrades].size.zero?)
    assert(result[:found_upgrades].size.zero?)

    assert("USS Troi", andromeda_ship.reload.name)
    assert("Contorta", pirate_ship.reload.name)
  end
end
