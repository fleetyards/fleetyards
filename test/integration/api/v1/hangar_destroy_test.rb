# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarDestroyTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user
  end

  test "empties a hangar whose vehicles carry loadouts" do
    vehicle = create(:vehicle, user: @user)
    create(:vehicle_loadout, vehicle: vehicle)

    delete "/api/v1/hangar", as: :json

    assert_equal 204, response.status
    assert_empty Vehicle.where(id: vehicle.id)
    assert_empty VehicleLoadout.where(vehicle_id: vehicle.id)
  end

  test "takes the rows that hang off the vehicles it deletes" do
    vehicle = create(:vehicle, user: @user)
    TaskForce.create!(vehicle: vehicle, hangar_group: create(:hangar_group, user: @user))
    FleetVehicle.create!(fleet: create(:fleet), vehicle: vehicle)

    delete "/api/v1/hangar", as: :json

    assert_equal 204, response.status
    assert_empty TaskForce.where(vehicle_id: vehicle.id)
    assert_empty FleetVehicle.where(vehicle_id: vehicle.id)
  end

  test "keeps the wishlist and every other hangar" do
    purchased = create(:vehicle, user: @user)
    wanted = create(:vehicle, :wanted, user: @user)
    other = create(:vehicle, user: create(:user))

    delete "/api/v1/hangar", as: :json

    assert_equal 204, response.status
    assert_empty Vehicle.where(id: purchased.id)
    assert_equal 1, Vehicle.where(id: wanted.id).count
    assert_equal 1, Vehicle.where(id: other.id).count
  end
end
