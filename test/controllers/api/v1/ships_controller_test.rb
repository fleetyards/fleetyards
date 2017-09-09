# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class ShipsControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::ShipsController
      fixtures :ships, :manufacturers, :ship_roles

      let(:ship) { ships :andromeda }

      before do
        ship
      end

      test "#index" do
        get :index

        assert_response :ok

        json = JSON.parse(response.body)
        assert_equal 2, json.size
        ship_data = json.find { |item| item["name"] == ship.name }
        assert_equal ship.id, ship_data["id"]
        assert_equal ship.name, ship_data["name"]
        assert_equal ship.addition.mass, ship_data["mass"]
        assert_equal ship.addition.net_cargo, ship_data["netCargo"]
        assert_equal ship.addition.cargo, ship_data["cargo"]
      end

      describe "#updated" do
        let(:updatedShip) { ships :andromeda }

        test "should return list of updated ships" do
          Timecop.freeze(Time.zone.now) do
            updatedShip

            get :updated, params: { from: (Time.zone.now - 1.day) }

            assert_response :ok

            json = JSON.parse(response.body)
            assert_equal 2, json.size
            ship_data = json.find { |item| item["name"] == ship.name }
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

      describe "#filters" do
        let(:manufacturer) { manufacturers :origin }
        let(:ship) { ships :explorer }
        let(:ship_role) { ship_roles :explorer }

        before do
          ship
          manufacturer
          ship_role
        end

        test "should return list of ship filters" do
          get :filters

          assert_response :ok

          json = JSON.parse(response.body)
          assert_equal 11, json.size
          assert_equal 1, json.select { |item| item['category'] == 'manufacturer' }.size
          assert_equal 2, json.select { |item| item['category'] == 'classification' }.size
          assert_equal 5, json.select { |item| item['category'] == 'productionStatus' }.size
          assert_equal 1, json.select { |item| item['category'] == 'shipRole' }.size
          assert_equal 2, json.select { |item| item['category'] == 'onSale' }.size
        end
      end
    end
  end
end
