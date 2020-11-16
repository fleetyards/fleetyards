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
        let(:explorer) { data.vehicles.includes(:model).find_by(models: { name: '600i' }) }
        let(:enterprise) { data.vehicles.includes(:model).find_by(models: { name: 'Andromeda' }) }

        before do
          sign_in data
        end

        it 'should return list for index' do
          get :index

          assert_response :ok
          json = JSON.parse response.body

          expected = [{
            'id' => explorer.id,
            'name' => '',
            'purchased' => true,
            'public' => true,
            'loaner' => false,
            'flagship' => false,
            'nameVisible' => false,
            'saleNotify' => false,
            'model' => {
              'id' => explorer.model_id,
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
              'storeImage' => explorer.model.store_image.url,
              'storeImageMedium' => explorer.model.store_image.medium.url,
              'storeImageSmall' => explorer.model.store_image.small.url,
              'fleetchartImage' => nil,
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
              'rsiId' => 14_101,
              'hasImages' => false,
              'hasVideos' => false,
              'hasModules' => false,
              'hasUpgrades' => false,
              'hasPaints' => false,
              'lastUpdatedAt' => explorer.model.last_updated_at&.utc&.iso8601,
              'lastUpdatedAtLabel' => (I18n.l(explorer.model.last_updated_at&.utc, format: :label) if explorer.model.last_updated_at.present?),
              'soldAt' => [],
              'boughtAt' => [],
              'manufacturer' => {
                'name' => 'Origin',
                'slug' => 'origin',
                'code' => nil,
                'logo' => nil
              },
              'createdAt' => explorer.model.created_at.utc.iso8601,
              'updatedAt' => explorer.model.updated_at.utc.iso8601
            },
            'paint' => nil,
            'upgrade' => nil,
            'hangarGroupIds' => explorer.hangar_group_ids,
            'hangarGroups' => explorer.hangar_groups.map do |hangar_group|
              {
                'id' => hangar_group.id,
                'name' => hangar_group.name,
                'color' => hangar_group.color
              }
            end,
            'modelModuleIds' => explorer.model_module_ids,
            'modelUpgradeIds' => explorer.model_upgrade_ids,
            'createdAt' => explorer.created_at.utc.iso8601,
            'updatedAt' => explorer.updated_at.utc.iso8601
          }, {
            'id' => enterprise.id,
            'name' => 'Enterprise',
            'purchased' => true,
            'public' => true,
            'loaner' => false,
            'flagship' => false,
            'nameVisible' => false,
            'saleNotify' => false,
            'model' => {
              'id' => enterprise.model.id,
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
              'storeImage' => enterprise.model.store_image.url,
              'storeImageMedium' => enterprise.model.store_image.medium.url,
              'storeImageSmall' => enterprise.model.store_image.small.url,
              'fleetchartImage' => nil,
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
              'rsiId' => 14_100,
              'hasImages' => false,
              'hasVideos' => false,
              'hasModules' => false,
              'hasUpgrades' => false,
              'hasPaints' => false,
              'lastUpdatedAt' => enterprise.model.last_updated_at&.utc&.iso8601,
              'lastUpdatedAtLabel' => (I18n.l(enterprise.model.last_updated_at&.utc, format: :label) if enterprise.model.last_updated_at.present?),
              'soldAt' => [],
              'boughtAt' => [],
              'manufacturer' => {
                'name' => 'RSI',
                'slug' => 'rsi',
                'code' => nil,
                'logo' => nil
              },
              'createdAt' => enterprise.model.created_at.utc.iso8601,
              'updatedAt' => enterprise.model.updated_at.utc.iso8601
            },
            'paint' => nil,
            'upgrade' => nil,
            'hangarGroupIds' => enterprise.hangar_group_ids,
            'hangarGroups' => enterprise.hangar_groups.map do |hangar_group|
              {
                'id' => hangar_group.id,
                'name' => hangar_group.name,
                'color' => hangar_group.color
              }
            end,
            'modelModuleIds' => enterprise.model_module_ids,
            'modelUpgradeIds' => enterprise.model_upgrade_ids,
            'createdAt' => enterprise.created_at.utc.iso8601,
            'updatedAt' => enterprise.updated_at.utc.iso8601
          }]
          assert_equal expected, json
        end

        it 'should return list for index when filtered' do
          query_params = {
            hangarGroupsIn: enterprise.hangar_groups.map(&:slug)
          }
          get :index, params: { q: query_params.to_json }

          assert_response :ok
          json = JSON.parse response.body

          expected = [{
            'id' => enterprise.id,
            'name' => 'Enterprise',
            'purchased' => true,
            'loaner' => false,
            'flagship' => false,
            'public' => true,
            'nameVisible' => false,
            'saleNotify' => false,
            'model' => {
              'id' => enterprise.model.id,
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
              'storeImage' => enterprise.model.store_image.url,
              'storeImageMedium' => enterprise.model.store_image.medium.url,
              'storeImageSmall' => enterprise.model.store_image.small.url,
              'fleetchartImage' => nil,
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
              'rsiId' => 14_100,
              'hasImages' => false,
              'hasVideos' => false,
              'hasModules' => false,
              'hasUpgrades' => false,
              'hasPaints' => false,
              'lastUpdatedAt' => enterprise.model.last_updated_at&.utc&.iso8601,
              'lastUpdatedAtLabel' => (I18n.l(enterprise.model.last_updated_at&.utc, format: :label) if enterprise.model.last_updated_at.present?),
              'soldAt' => [],
              'boughtAt' => [],
              'manufacturer' => {
                'name' => 'RSI',
                'slug' => 'rsi',
                'code' => nil,
                'logo' => nil
              },
              'createdAt' => enterprise.model.created_at.utc.iso8601,
              'updatedAt' => enterprise.model.updated_at.utc.iso8601
            },
            'paint' => nil,
            'upgrade' => nil,
            'hangarGroupIds' => enterprise.hangar_group_ids,
            'hangarGroups' => enterprise.hangar_groups.map do |hangar_group|
              {
                'id' => hangar_group.id,
                'name' => hangar_group.name,
                'color' => hangar_group.color
              }
            end,
            'modelModuleIds' => enterprise.model_module_ids,
            'modelUpgradeIds' => enterprise.model_upgrade_ids,
            'createdAt' => enterprise.created_at.utc.iso8601,
            'updatedAt' => enterprise.updated_at.utc.iso8601
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
