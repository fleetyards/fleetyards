# frozen_string_literal: true

require "test_helper"
require "hangar_sync"
require "rsi/models_loader"

class HangarSyncTest < ActiveSupport::TestCase
  let(:loader) { ::Rsi::ModelsLoader.new }
  let(:user) { users :troi }
  let(:input) { JSON.parse(Rails.root.join("test/fixtures/sync/rsi_hangar.json").read) }

  before do
    VCR.use_cassette("rsi_models_loader_all") do
      loader.all
    end
  end

  it "syncs all data" do
    result = ::HangarSync.new(input).run(user.id)

    assert_equal(["3d543e17-aefe-5392-973b-2c2806eb9aa6"], result[:found_vehicles])
    assert_equal(["9458bcf1-e6f8-59f0-8c1f-5f0a19b3af00"], result[:moved_vehicles_to_wanted])
    assert_equal(48, result[:imported_vehicles].size)
    assert_equal(3, result[:missing_components].size)
    assert_equal(7, result[:missing_models].size)
    assert(result[:imported_components].size.zero?)
    assert(result[:found_components].size.zero?)
    assert(result[:missing_component_vehicles].size.zero?)
    assert(result[:imported_upgrades].size.zero?)
    assert(result[:found_upgrades].size.zero?)
  end
end
