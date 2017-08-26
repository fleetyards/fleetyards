# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class ShipsControllerTest < ActionController::TestCase
      tests Api::V1::ShipsController

      let(:ship) { ships :esperanza }

      before do
        ship
      end

      test "#index" do
        get :index

        assert_response :ok

        json = JSON.parse(response.body)
        assert_equal json.size, 1
        ship_data = json.first
        assert_equal ship.id, ship_data["id"]
        assert_equal ship.name, ship_data["name"]
      end

      describe "#updated" do
        let(:updatedShip) { ships :esperanza }

        test "should return list of updated ships" do
          Timecop.freeze(Time.zone.now) do
            updatedShip

            get :updated, params: { from: (Time.zone.now - 1.day) }

            assert_response :ok

            json = JSON.parse(response.body)
            assert_equal json.size, 1
            ship_data = json.first
            assert_equal ship.id, ship_data["id"]
            assert_equal ship.name, ship_data["name"]
          end
        end

        test "should return empty list when no ship is modified" do
          get :updated

          assert_response :not_modified

          json = JSON.parse(response.body)
          assert_equal(json, [])
        end
      end
    end
  end
end
