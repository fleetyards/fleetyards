# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class HangarStatsControllerTest < ActionController::TestCase
      let(:data) { users :data }

      setup do
        data

        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::HangarStatsController

      describe 'without session' do
        it 'should render 403 for quick-stats' do
          get :index

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        it 'should render 200 for public quick-stats' do
          get :public_index, params: { username: 'data' }

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
      end

      describe 'with session' do
        before do
          sign_in data
        end

        it 'should return counts for quick-stats' do
          get :index

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

        it 'should return counts for quick-stats' do
          get :index, params: { q: '{ "classificationIn": ["combat"] }' }

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
      end
    end
  end
end
