# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class VehiclesControllerTest < ActionController::TestCase
      tests Api::V1::VehiclesController

      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s

        @data = users :data
      end

      test 'should render 403 for index' do
        get :index

        assert_response :unauthorized

        json = JSON.parse response.body

        assert_equal 'unauthorized', json['code']
      end

      test 'should render 403 for quick-stats' do
        get :quick_stats

        assert_response :unauthorized

        json = JSON.parse response.body

        assert_equal 'unauthorized', json['code']
      end

      test 'should render 200 for public quick-stats' do
        get :public_quick_stats, params: { username: 'data' }

        assert_response :ok

        json = JSON.parse response.body

        expected = {
          'total' => 2,
          'classifications' => [{
            'name' => 'explorer',
            'label' => 'Explorer',
            'count' => 1
          }, {
            'name' => 'multi_role',
            'label' => 'Multi role',
            'count' => 1
          }],
          'groups' => []
        }

        assert_equal expected, json
      end

      test 'should render 403 for hangar-items' do
        get :hangar_items

        assert_response :unauthorized

        json = JSON.parse response.body

        assert_equal 'unauthorized', json['code']
      end

      test 'with session should return list for index' do
        explorer = @data.vehicles.includes(:model).find_by(models: { name: '600i' })
        enterprise = @data.vehicles.includes(:model).find_by(models: { name: 'Andromeda' })

        sign_in(@data)

        get :index

        assert_response :ok
        json = JSON.parse response.body
        result = json.map { |item| item['id'] }

        assert_equal [explorer.id, enterprise.id], result
      end

      test 'with session should return list for index when filtered' do
        enterprise = @data.vehicles.includes(:model).find_by(models: { name: 'Andromeda' })

        sign_in(@data)

        query_params = {
          hangarGroupsIn: enterprise.hangar_groups.map(&:slug)
        }
        get :index, params: { q: query_params.to_json }

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['id'] }

        assert_equal [enterprise.id], result
      end

      test 'with session should return counts for quick-stats' do
        sign_in(@data)

        get :quick_stats

        assert_response :ok

        json = JSON.parse response.body

        expected = {
          'total' => 2,
          'classifications' => [{
            'name' => 'explorer',
            'label' => 'Explorer',
            'count' => 1
          }, {
            'name' => 'multi_role',
            'label' => 'Multi role',
            'count' => 1
          }],
          'groups' => [],
          'metrics' => {
            'totalMoney' => 625,
            'totalMinCrew' => 5,
            'totalMaxCrew' => 10,
            'totalCargo' => 130
          }
        }

        assert_equal expected, json
      end

      test 'with session should return counts for filtered quick-stats' do
        sign_in(@data)

        get :quick_stats, params: { q: '{ "classificationIn": ["combat"] }' }

        assert_response :ok

        json = JSON.parse response.body

        expected = {
          'total' => 0,
          'classifications' => [{
            'name' => 'explorer',
            'label' => 'Explorer',
            'count' => 0
          }, {
            'name' => 'multi_role',
            'label' => 'Multi role',
            'count' => 0
          }],
          'groups' => [],
          'metrics' => {
            'totalMoney' => 0,
            'totalMinCrew' => 0,
            'totalMaxCrew' => 0,
            'totalCargo' => 0
          }
        }

        assert_equal expected, json
      end

      test 'with session should render 200 for hangar-items' do
        sign_in(@data)

        get :hangar_items

        assert_response :ok

        json = JSON.parse response.body

        expected = %w[
          600i
          andromeda
        ]
        assert_equal expected, json
      end
    end
  end
end
