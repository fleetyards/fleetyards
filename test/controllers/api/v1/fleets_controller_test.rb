# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class FleetsControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::FleetsController

      describe 'without session' do
        it 'should render 200 for index' do
          get :index

          assert_response :ok
          json = JSON.parse response.body

          expected = [{
            'name' => 'RSI',
            'sid' => 'rsi',
            'logo' => nil,
            'banner' => nil,
            'background' => nil,
            'archetype' => nil,
            'mainActivity' => nil,
            'secondaryActivity' => nil,
            'recruiting' => nil,
            'commitment' => nil,
            'rpg' => nil,
            'exclusive' => nil,
            'memberCount' => nil,
            'createdAt' => Fleet.first.created_at.to_time.iso8601,
            'updatedAt' => Fleet.first.updated_at.to_time.iso8601
          }, {
            'name' => 'TMI',
            'sid' => 'tmi',
            'logo' => nil,
            'banner' => nil,
            'background' => nil,
            'archetype' => nil,
            'mainActivity' => nil,
            'secondaryActivity' => nil,
            'recruiting' => nil,
            'commitment' => nil,
            'rpg' => nil,
            'exclusive' => nil,
            'memberCount' => nil,
            'createdAt' => Fleet.last.created_at.to_time.iso8601,
            'updatedAt' => Fleet.last.updated_at.to_time.iso8601
          }]

          assert_equal expected, json
        end

        it 'should render 200 for show' do
          get :show, params: { sid: 'tmi' }

          assert_response :ok
          json = JSON.parse response.body

          expected = {
            'name' => 'TMI',
            'sid' => 'tmi',
            'logo' => nil,
            'banner' => nil,
            'background' => nil,
            'archetype' => nil,
            'mainActivity' => nil,
            'secondaryActivity' => nil,
            'recruiting' => nil,
            'commitment' => nil,
            'rpg' => nil,
            'exclusive' => nil,
            'memberCount' => nil,
            'createdAt' => Fleet.last.created_at.to_time.iso8601,
            'updatedAt' => Fleet.last.updated_at.to_time.iso8601
          }

          assert_equal expected, json
        end

        it 'should render 401 for my' do
          get :my

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        it 'should render 401 for count' do
          get :count, params: { sid: 'tmi' }

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        it 'should render 401 for models' do
          get :models, params: { sid: 'tmi' }

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end
      end

      describe 'with session' do
        let(:data) { users :data }

        before do
          add_authorization data
        end

        it 'should return list for index' do
          get :index

          assert_response :ok
          json = JSON.parse response.body

          expected = [{
            'name' => 'RSI',
            'sid' => 'rsi',
            'logo' => nil,
            'banner' => nil,
            'background' => nil,
            'archetype' => nil,
            'mainActivity' => nil,
            'secondaryActivity' => nil,
            'recruiting' => nil,
            'commitment' => nil,
            'rpg' => nil,
            'exclusive' => nil,
            'memberCount' => nil,
            'createdAt' => Fleet.first.created_at.to_time.iso8601,
            'updatedAt' => Fleet.first.updated_at.to_time.iso8601
          }]

          assert_equal expected, json
        end

        it 'should return list for my' do
          get :my

          assert_response :ok
          json = JSON.parse response.body

          expected = [{
            'name' => 'TMI',
            'sid' => 'tmi',
            'logo' => nil,
            'banner' => nil,
            'background' => nil,
            'archetype' => nil,
            'mainActivity' => nil,
            'secondaryActivity' => nil,
            'recruiting' => nil,
            'commitment' => nil,
            'rpg' => nil,
            'exclusive' => nil,
            'memberCount' => nil,
            'createdAt' => Fleet.last.created_at.to_time.iso8601,
            'updatedAt' => Fleet.last.updated_at.to_time.iso8601
          }]

          assert_equal expected, json
        end

        it 'should render 200 for show' do
          get :show, params: { sid: 'rsi' }

          assert_response :ok
          json = JSON.parse response.body

          expected = {
            'name' => 'RSI',
            'sid' => 'rsi',
            'logo' => nil,
            'banner' => nil,
            'background' => nil,
            'archetype' => nil,
            'mainActivity' => nil,
            'secondaryActivity' => nil,
            'recruiting' => nil,
            'commitment' => nil,
            'rpg' => nil,
            'exclusive' => nil,
            'memberCount' => nil,
            'createdAt' => Fleet.first.created_at.to_time.iso8601,
            'updatedAt' => Fleet.first.updated_at.to_time.iso8601
          }

          assert_equal expected, json
        end

        it 'should render 403 for count of fleet without access' do
          get :count, params: { sid: 'rsi' }

          assert_response :forbidden
          json = JSON.parse response.body
          assert_equal 'forbidden', json['code']
        end

        it 'should render 403 for models of fleet without access' do
          get :models, params: { sid: 'rsi' }

          assert_response :forbidden
          json = JSON.parse response.body
          assert_equal 'forbidden', json['code']
        end

        it 'should render 200 for count' do
          get :count, params: { sid: 'tmi' }

          assert_response :ok
          json = JSON.parse response.body

          expected = {
            'total' => 2,
            'classifications' => [{
              'name' => 'multi_role',
              'label' => 'Multi role',
              'count' => 1
            }, {
              'name' => 'explorer',
              'label' => 'Explorer',
              'count' => 1
            }],
            'models' => {
              '600i' => 1,
              'andromeda' => 1
            }
          }

          assert_equal expected, json
        end

        it 'should render 200 for models' do
          get :models, params: { sid: 'tmi' }

          assert_response :ok
          json = JSON.parse response.body

          expected = [{
            'id' => data.vehicles.first.model.id,
            'name' => '600i',
            'rsiName' => nil,
            'slug' => '600i',
            'rsiSlug' => nil,
            'description' => nil,
            'length' => 20.0,
            'beam' => 0.0,
            'height' => 0.0,
            'mass' => 0.0,
            'cargo' => 40.0,
            'cargoLabel' => '600i (40 SCU)',
            'minCrew' => 2,
            'maxCrew' => 5,
            'scmSpeed' => nil,
            'afterburnerSpeed' => nil,
            'groundSpeed' => nil,
            'afterburnerGroundSpeed' => nil,
            'pitchMax' => nil,
            'yawMax' => nil,
            'rollMax' => nil,
            'xaxisAcceleration' => nil,
            'yaxisAcceleration' => nil,
            'zaxisAcceleration' => nil,
            'size' => nil,
            'sizeLabel' => nil,
            'storeImage' => data.vehicles.first.model.store_image.url,
            'storeImageMedium' => data.vehicles.first.model.store_image.medium.url,
            'storeImageThumb' => data.vehicles.first.model.store_image.small.url,
            'fleetchartImage' => nil,
            'backgroundImage' => nil,
            'brochure' => nil,
            'storeUrl' => 'https://robertsspaceindustries.com',
            'price' => nil,
            'pledgePrice' => nil,
            'lastPledgePrice' => 400.0,
            'onSale' => false,
            'productionStatus' => nil,
            'productionNote' => nil,
            'classification' => 'explorer',
            'classificationLabel' => 'Explorer',
            'focus' => nil,
            'rsiId' => 141,
            'hasImages' => false,
            'hasVideos' => false,
            'hasModules' => false,
            'hasUpgrades' => false,
            'manufacturer' => {
              'name' => 'Origin',
              'slug' => 'origin',
              'code' => nil,
              'logo' => nil
            },
            'createdAt' => data.vehicles.first.model.created_at.to_time.iso8601,
            'updatedAt' => data.vehicles.first.model.updated_at.to_time.iso8601
          }, {
            'id' => data.vehicles.last.model.id,
            'name' => 'Andromeda',
            'rsiName' => nil,
            'slug' => 'andromeda',
            'rsiSlug' => nil,
            'description' => nil,
            'length' => 61.2,
            'beam' => 10.2,
            'height' => 10.2,
            'mass' => 1000.02,
            'cargo' => 90.0,
            'cargoLabel' => 'Andromeda (90 SCU)',
            'minCrew' => 3,
            'maxCrew' => 5,
            'scmSpeed' => nil,
            'afterburnerSpeed' => nil,
            'groundSpeed' => nil,
            'afterburnerGroundSpeed' => nil,
            'pitchMax' => nil,
            'yawMax' => nil,
            'rollMax' => nil,
            'xaxisAcceleration' => nil,
            'yaxisAcceleration' => nil,
            'zaxisAcceleration' => nil,
            'size' => nil,
            'sizeLabel' => nil,
            'storeImage' => data.vehicles.last.model.store_image.url,
            'storeImageMedium' => data.vehicles.last.model.store_image.medium.url,
            'storeImageThumb' => data.vehicles.last.model.store_image.small.url,
            'fleetchartImage' => nil,
            'backgroundImage' => nil,
            'brochure' => nil,
            'storeUrl' => 'https://robertsspaceindustries.com',
            'price' => nil,
            'pledgePrice' => nil,
            'lastPledgePrice' => 225.0,
            'onSale' => false,
            'productionStatus' => nil,
            'productionNote' => nil,
            'classification' => 'multi_role',
            'classificationLabel' => 'Multi role',
            'focus' => nil,
            'rsiId' => nil,
            'hasImages' => false,
            'hasVideos' => false,
            'hasModules' => false,
            'hasUpgrades' => false,
            'manufacturer' => {
              'name' => 'RSI',
              'slug' => 'rsi',
              'code' => nil,
              'logo' => nil
            },
            'createdAt' => data.vehicles.last.model.created_at.to_time.iso8601,
            'updatedAt' => data.vehicles.last.model.updated_at.to_time.iso8601
          }]

          assert_equal expected, json
        end
      end
    end
  end
end
