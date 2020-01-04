# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class VehiclesControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::VehiclesController

      describe 'without session' do
        it 'should render 403 for index' do
          get :index

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        it 'should render 403 for quick-stats' do
          get :quick_stats

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        it 'should render 200 for public quick-stats' do
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
            }]
          }
          assert_equal expected, json
        end

        it 'should render 403 for hangar-items' do
          get :hangar_items

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end
      end

      describe 'with session' do
        let(:data) { users :data }

        before do
          sign_in data
        end

        it 'should return list for index' do
          get :index

          assert_response :ok
          json = JSON.parse response.body

          expected = [{
            'id' => data.vehicles.first.id,
            'name' => '',
            'purchased' => true,
            'public' => true,
            'flagship' => false,
            'nameVisible' => false,
            'saleNotify' => false,
            'model' => {
              'id' => data.vehicles.first.model_id,
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
              'storeImageSmall' => data.vehicles.first.model.store_image.small.url,
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
              'lastUpdatedAt' => data.vehicles.first.model.last_updated_at&.utc&.iso8601,
              'lastUpdatedAtLabel' => (I18n.l(data.vehicles.first.model.last_updated_at&.utc, format: :label) if data.vehicles.first.model.last_updated_at.present?),
              'manufacturer' => {
                'name' => 'Origin',
                'slug' => 'origin',
                'code' => nil,
                'logo' => nil
              },
              'createdAt' => data.vehicles.first.model.created_at.utc.iso8601,
              'updatedAt' => data.vehicles.first.model.updated_at.utc.iso8601
            },
            'hangarGroupIds' => data.vehicles.first.hangar_group_ids,
            'modelModuleIds' => data.vehicles.first.model_module_ids,
            'modelUpgradeIds' => data.vehicles.first.model_upgrade_ids,
            'createdAt' => data.vehicles.first.created_at.utc.iso8601,
            'updatedAt' => data.vehicles.first.updated_at.utc.iso8601
          }, {
            'id' => data.vehicles.last.id,
            'name' => 'Enterprise',
            'purchased' => true,
            'public' => true,
            'flagship' => false,
            'nameVisible' => false,
            'saleNotify' => false,
            'model' => {
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
              'cargo' => 90,
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
              'storeImageSmall' => data.vehicles.last.model.store_image.small.url,
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
              'lastUpdatedAt' => data.vehicles.last.model.last_updated_at&.utc&.iso8601,
              'lastUpdatedAtLabel' => (I18n.l(data.vehicles.last.model.last_updated_at&.utc, format: :label) if data.vehicles.last.model.last_updated_at.present?),
              'manufacturer' => {
                'name' => 'RSI',
                'slug' => 'rsi',
                'code' => nil,
                'logo' => nil
              },
              'createdAt' => data.vehicles.last.model.created_at.utc.iso8601,
              'updatedAt' => data.vehicles.last.model.updated_at.utc.iso8601
            },
            'hangarGroupIds' => data.vehicles.last.hangar_group_ids,
            'modelModuleIds' => data.vehicles.last.model_module_ids,
            'modelUpgradeIds' => data.vehicles.last.model_upgrade_ids,
            'createdAt' => data.vehicles.last.created_at.utc.iso8601,
            'updatedAt' => data.vehicles.last.updated_at.utc.iso8601
          }]
          assert_equal expected, json
        end

        it 'should return list for index when filtered' do
          query_params = {
            hangarGroupsIn: data.vehicles.last.hangar_groups.map(&:slug)
          }
          get :index, params: { q: query_params.to_json }

          assert_response :ok
          json = JSON.parse response.body

          expected = [{
            'id' => data.vehicles.last.id,
            'name' => 'Enterprise',
            'purchased' => true,
            'public' => true,
            'flagship' => false,
            'nameVisible' => false,
            'saleNotify' => false,
            'model' => {
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
              'cargo' => 90,
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
              'storeImageSmall' => data.vehicles.last.model.store_image.small.url,
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
              'lastUpdatedAt' => data.vehicles.last.model.last_updated_at&.utc&.iso8601,
              'lastUpdatedAtLabel' => (I18n.l(data.vehicles.last.model.last_updated_at&.utc, format: :label) if data.vehicles.last.model.last_updated_at.present?),
              'manufacturer' => {
                'name' => 'RSI',
                'slug' => 'rsi',
                'code' => nil,
                'logo' => nil
              },
              'createdAt' => data.vehicles.last.model.created_at.utc.iso8601,
              'updatedAt' => data.vehicles.last.model.updated_at.utc.iso8601
            },
            'hangarGroupIds' => data.vehicles.last.hangar_group_ids,
            'modelModuleIds' => data.vehicles.last.model_module_ids,
            'modelUpgradeIds' => data.vehicles.last.model_upgrade_ids,
            'createdAt' => data.vehicles.last.created_at.utc.iso8601,
            'updatedAt' => data.vehicles.last.updated_at.utc.iso8601
          }]
          assert_equal expected, json
        end

        it 'should return counts for quick-stats' do
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
          get :quick_stats, params: { q: '{ "classificationIn": ["combat"] }' }

          assert_response :ok
          json = JSON.parse response.body

          expected = {
            'total' => 0,
            'classifications' => [],
            'metrics' => {
              'totalMoney' => 0,
              'totalMinCrew' => 0,
              'totalMaxCrew' => 0,
              'totalCargo' => 0
            }
          }
          assert_equal expected, json
        end

        it 'should render 200 for hangar-items' do
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
end
