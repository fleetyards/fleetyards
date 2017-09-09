# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class HangarsControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::HangarsController

      let(:data) { users :data }
      let(:enterprise) { user_ships :enterprise }

      let(:will) { users :will }

      before do
        enterprise
      end

      describe 'without session' do
        test "#show" do
          get :show

          assert_response :unauthorized
        end
      end

      describe 'with session without ship' do
        before do
          add_authorization will
        end

        test "#show" do
          get :show

          assert_response :ok

          json = JSON.parse(response.body)
          assert_equal 0, json.size
        end
      end

      describe 'with session and ship' do
        before do
          add_authorization data
        end

        test "#show" do
          get :show

          assert_response :ok

          json = JSON.parse(response.body)
          assert_equal 1, json.size
          # ship_data = json.first
          # assert_equal ship.id, ship_data["id"]
          # assert_equal ship.name, ship_data["name"]
          # assert_equal ship.addition.mass, ship_data["mass"]
          # assert_equal ship.addition.net_cargo, ship_data["netCargo"]
          # assert_equal ship.addition.cargo, ship_data["cargo"]
        end
      end
    end
  end
end
