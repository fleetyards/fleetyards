# frozen_string_literal: true

require "test_helper"
require_relative "../support/hangar_import_fixtures"

class HangarSyncTest < ActiveSupport::TestCase
  include HangarImportFixtures

  setup do
    load_loader_fixtures
    @user = create(:user)
    @input = JSON.parse(Rails.root.join("spec/fixtures/sync/rsi_hangar.json").read)
  end

  class WithExistingVehiclesTest < HangarSyncTest
    setup do
      @andromeda_model = Model.find_by!(slug: "rsi-constellation-andromeda")
      @corsair_model = Model.find_by!(slug: "drak-corsair")
      @javelin_model = Model.find_by!(slug: "aegs-javelin")

      @andromeda_ship = create(:vehicle, user: @user, model: @andromeda_model, name: "USS Troi", wanted: false, public: true)
      @pirate_ship = create(:vehicle, user: @user, model: @corsair_model, wanted: false)
      @jav_ship = create(:vehicle, user: @user, model: @javelin_model, wanted: false, public: true, flagship: true)
    end

    test "syncs all data" do
      travel_to 1.minute.from_now do
        result = ::HangarSync.new(@input).run(@user.id)

        assert_equal [@andromeda_ship.id, @pirate_ship.id].sort, result[:found_vehicles].sort
        assert_equal [@jav_ship.id], result[:moved_vehicles_to_wanted]
        assert_equal 47, result[:imported_vehicles].size
        assert_equal [], result[:missing_components]
        assert_equal [], result[:missing_models]
        assert_equal [], result[:imported_components]
        assert_equal [], result[:found_components]
        assert_equal [], result[:missing_component_vehicles]
        assert_equal [], result[:imported_upgrades]
        assert_equal [], result[:found_upgrades]

        assert_equal "USS Troi", @andromeda_ship.reload.name
        assert_equal "Enterprise", @pirate_ship.reload.name
      end
    end
  end

  class WithBundledSnubCraftsTest < HangarSyncTest
    setup do
      @andromeda_model = Model.find_by!(slug: "rsi-constellation-andromeda")
      @snub_model = Model.find_by!(slug: "drak-corsair")
      @andromeda_model.snub_crafts << @snub_model
    end

    test "auto-creates bundled child vehicles for synced ships" do
      result = ::HangarSync.new(@input).run(@user.id)

      andromeda_vehicle = Vehicle.find(result[:imported_vehicles]).find { |v| v.model_id == @andromeda_model.id }
      assert andromeda_vehicle.present?

      bundled = Vehicle.where(bundled: true, vehicle_id: andromeda_vehicle.id, user_id: @user.id)
      assert_equal 1, bundled.count
      assert_equal @snub_model.id, bundled.first.model_id
    end

    test "does not move bundled children to wanted during reconciliation" do
      andromeda_vehicle = create(:vehicle, user: @user, model: @andromeda_model, wanted: false)
      bundled = Vehicle.find_by(bundled: true, vehicle_id: andromeda_vehicle.id)
      assert bundled.present?

      ::HangarSync.new(@input).run(@user.id)

      assert_equal true, bundled.reload.bundled
      assert_equal false, bundled.wanted
    end
  end

  class WhenRsiPledgeIdChangesTest < HangarSyncTest
    setup do
      @andromeda_model = Model.find_by!(slug: "rsi-constellation-andromeda")
      @andromeda_ship = create(:vehicle, user: @user, model: @andromeda_model, name: "USS Troi", wanted: false, public: true,
        rsi_pledge_id: "OLD_PLEDGE_ID", rsi_pledge_synced_at: 1.day.ago)
    end

    test "updates the existing vehicle instead of creating a duplicate" do
      travel_to 1.minute.from_now do
        result = ::HangarSync.new(@input).run(@user.id)

        assert_includes result[:found_vehicles], @andromeda_ship.id
        refute_includes result[:moved_vehicles_to_wanted], @andromeda_ship.id

        @andromeda_ship.reload
        assert_equal "00064313", @andromeda_ship.rsi_pledge_id
        assert_equal false, @andromeda_ship.wanted
        assert_equal "USS Troi", @andromeda_ship.name

        andromeda_vehicles = Vehicle.where(user_id: @user.id, model_id: @andromeda_model.id)
        assert_equal 1, andromeda_vehicles.count
      end
    end
  end
end
