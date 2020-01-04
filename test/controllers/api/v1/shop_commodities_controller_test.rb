# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ShopCommoditiesControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::ShopCommoditiesController

      let(:new_deal) { shops :new_deal }
      let(:explorer) { shop_commodities :commodity_three }
      let(:andromeda) { shop_commodities :commodity_four }
      let(:index_result) do
        [{
          'name' => '600i',
          'slug' => '600i',
          'storeImage' => explorer.commodity_item.store_image.url,
          'storeImageMedium' => explorer.commodity_item.store_image.medium.url,
          'storeImageSmall' => explorer.commodity_item.store_image.small.url,
          'category' => 'model',
          'subCategory' => 'explorer',
          'subCategoryLabel' => 'Explorer',
          'description' => nil,
          'pricePerUnit' => false,
          'sellPrice' => nil,
          'buyPrice' => nil,
          'rentPrice1Day' => nil,
          'rentPrice3Days' => nil,
          'rentPrice7Days' => nil,
          'rentPrice30Days' => nil,
          'locationLabel' => andromeda.location_label,
          'shop' => {
            'name' => 'New Deal',
            'slug' => 'new-deal',
            'type' => 'ships',
            'typeLabel' => 'Ship Store',
            'locationLabel' => andromeda.shop.location_label,
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => andromeda.shop.store_image.url,
            'storeImageMedium' => andromeda.shop.store_image.medium.url,
            'storeImageSmall' => andromeda.shop.store_image.small.url,
            'station' => {
              'name' => andromeda.shop.station.name,
              'slug' => andromeda.shop.station.slug,
            },
          },
          'item' => {
            'id' => explorer.commodity_item.id,
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
            'storeImage' => explorer.commodity_item.store_image.url,
            'storeImageMedium' => explorer.commodity_item.store_image.medium.url,
            'storeImageSmall' => explorer.commodity_item.store_image.small.url,
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
            'lastUpdatedAt' => explorer.commodity_item.last_updated_at&.utc&.iso8601,
            'lastUpdatedAtLabel' => (I18n.l(explorer.commodity_item.last_updated_at&.utc, format: :label) if explorer.commodity_item.last_updated_at.present?),
            'manufacturer' => {
              'name' => 'Origin',
              'slug' => 'origin',
              'code' => nil,
              'logo' => nil
            },
            'createdAt' => explorer.commodity_item.created_at.utc.iso8601,
            'updatedAt' => explorer.commodity_item.updated_at.utc.iso8601
          },
          'createdAt' => explorer.created_at.utc.iso8601,
          'updatedAt' => explorer.updated_at.utc.iso8601
        }, {
          'name' => 'Andromeda',
          'slug' => 'andromeda',
          'storeImage' => andromeda.commodity_item.store_image.url,
          'storeImageMedium' => andromeda.commodity_item.store_image.medium.url,
          'storeImageSmall' => andromeda.commodity_item.store_image.small.url,
          'category' => 'model',
          'subCategory' => 'multi_role',
          'subCategoryLabel' => 'Multi role',
          'description' => nil,
          'pricePerUnit' => false,
          'sellPrice' => nil,
          'buyPrice' => nil,
          'rentPrice1Day' => nil,
          'rentPrice3Days' => nil,
          'rentPrice7Days' => nil,
          'rentPrice30Days' => nil,
          'locationLabel' => andromeda.location_label,
          'shop' => {
            'name' => 'New Deal',
            'slug' => 'new-deal',
            'type' => 'ships',
            'typeLabel' => 'Ship Store',
            'locationLabel' => andromeda.shop.location_label,
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => andromeda.shop.store_image.url,
            'storeImageMedium' => andromeda.shop.store_image.medium.url,
            'storeImageSmall' => andromeda.shop.store_image.small.url,
            'station' => {
              'name' => andromeda.shop.station.name,
              'slug' => andromeda.shop.station.slug,
            },
          },
          'item' => {
            'id' => andromeda.commodity_item.id,
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
            'storeImage' => andromeda.commodity_item.store_image.url,
            'storeImageMedium' => andromeda.commodity_item.store_image.medium.url,
            'storeImageSmall' => andromeda.commodity_item.store_image.small.url,
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
            'lastUpdatedAt' => andromeda.commodity_item.last_updated_at&.utc&.iso8601,
            'lastUpdatedAtLabel' => (I18n.l(andromeda.commodity_item.last_updated_at&.utc, format: :label) if andromeda.commodity_item.last_updated_at.present?),
            'manufacturer' => {
              'name' => 'RSI',
              'slug' => 'rsi',
              'code' => nil,
              'logo' => nil
            },
            'createdAt' => andromeda.commodity_item.created_at.utc.iso8601,
            'updatedAt' => andromeda.commodity_item.updated_at.utc.iso8601
          },
          'createdAt' => andromeda.created_at.utc.iso8601,
          'updatedAt' => andromeda.updated_at.utc.iso8601
        }]
      end

      describe 'without session' do
        it 'should return list for index' do
          get :index, params: { station_slug: new_deal.station.slug, shop_slug: new_deal.slug }

          assert_response :ok
          json = JSON.parse response.body

          assert_equal index_result, json
        end
      end

      describe 'with session' do
        let(:data) { users :data }

        before do
          sign_in data
        end

        it 'should return list for index' do
          get :index, params: { station_slug: new_deal.station.slug, shop_slug: new_deal.slug }

          assert_response :ok
          json = JSON.parse response.body

          assert_equal index_result, json
        end
      end
    end
  end
end
