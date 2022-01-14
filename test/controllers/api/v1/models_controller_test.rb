# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ModelsControllerTest < ActionController::TestCase
      tests Api::V1::ModelsController

      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s

        @origin600i = Model.find_by(slug: '600i')
      end

      test 'should return list for index' do
        get :index

        assert_response :ok

        json = JSON.parse response.body
        result_names = json.map { |item| item['name'] }

        assert_equal [@origin600i.name, Model.last.name], result_names
      end

      test 'should be able to filter the list' do
        get :index, params: { q: '{ "nameCont": "Andromeda" }' }

        assert_response :ok
        json = JSON.parse response.body

        assert_equal 1, json.count
        assert_equal 'Andromeda', json.first['name']
      end

      test 'should be able to reduce per page size' do
        get :index, params: { perPage: '15' }

        assert_response :ok
        json = JSON.parse response.body

        # result count is 2 because there are only 2 models in the database
        assert_equal 2, json.count
      end

      test 'should return detail' do
        get :show, params: { slug: @origin600i.slug }

        assert_response :ok
        json = JSON.parse response.body

        expectation = {
          'id' => @origin600i.id,
          'name' => @origin600i.name,
          'scIdentifier' => nil,
          'erkulIdentifier' => nil,
          'rsiName' => nil,
          'slug' => @origin600i.slug,
          'rsiSlug' => nil,
          'description' => nil,
          'length' => 20.0,
          'fleetchartLength' => 20.0,
          'beam' => 0.0,
          'height' => 0.0,
          'mass' => 0.0,
          'cargo' => 40.0,
          'cargoLabel' => '600i (40 SCU)',
          'hydrogenFuelTankSize' => nil,
          'quantumFuelTankSize' => nil,
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
          'storeImage' => @origin600i.store_image.url,
          'storeImageLarge' => @origin600i.store_image.large.url,
          'storeImageMedium' => @origin600i.store_image.medium.url,
          'storeImageSmall' => @origin600i.store_image.small.url,
          'fleetchartImage' => nil,
          'topView' => nil,
          'topViewSmall' => nil,
          'topViewMedium' => nil,
          'topViewLarge' => nil,
          'topViewXlarge' => nil,
          'topViewWidth' => nil,
          'topViewHeight' => nil,
          'sideView' => nil,
          'sideViewSmall' => nil,
          'sideViewMedium' => nil,
          'sideViewLarge' => nil,
          'sideViewXlarge' => nil,
          'sideViewWidth' => nil,
          'sideViewHeight' => nil,
          'angledView' => nil,
          'angledViewSmall' => nil,
          'angledViewMedium' => nil,
          'angledViewLarge' => nil,
          'angledViewXlarge' => nil,
          'angledViewWidth' => nil,
          'angledViewHeight' => nil,
          'brochure' => nil,
          'holo' => nil,
          'holoColored' => false,
          'storeUrl' => 'https://robertsspaceindustries.com',
          'salesPageUrl' => nil,
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
          'lastUpdatedAt' => @origin600i.last_updated_at&.utc&.iso8601,
          'lastUpdatedAtLabel' => (I18n.l(Model.first.last_updated_at&.utc, format: :label) if @origin600i.last_updated_at.present?),
          'soldAt' => [],
          'boughtAt' => [],
          'listedAt' => [{
            'id' => @origin600i.listed_at.first.id,
            'name' => @origin600i.name,
            'slug' => @origin600i.slug,
            'storeImage' => @origin600i.store_image.url,
            'storeImageLarge' => @origin600i.store_image.large.url,
            'storeImageMedium' => @origin600i.store_image.medium.url,
            'storeImageSmall' => @origin600i.store_image.small.url, 'category' => 'model',
            'subCategory' => 'explorer',
            'subCategoryLabel' => 'Explorer',
            'description' => nil,
            'pricePerUnit' => false,
            'sellPrice' => nil,
            'averageSellPrice' => nil,
            'buyPrice' => nil,
            'averageBuyPrice' => nil,
            'rentalPrice1Day' => nil,
            'averageRentalPrice1Day' => nil,
            'rentalPrice3Days' => nil,
            'averageRentalPrice3Days' => nil,
            'rentalPrice7Days' => nil,
            'averageRentalPrice7Days' => nil,
            'rentalPrice30Days' => nil,
            'averageRentalPrice30Days' => nil,
            'locationLabel' => 'sold at Dumpers Depot on Port Olisar',
            'confirmed' => true,
            'commodityItemType' => 'Model',
            'commodityItemId' => @origin600i.id,
            'shop' => {
              'id' => 'fd71143a-7403-50e3-a5c0-32f62ab537b6',
              'name' => 'Dumpers Depot',
              'slug' => 'dumpers-depot',
              'type' => 'components',
              'typeLabel' => 'Components Store',
              'stationLabel' => 'at Port Olisar',
              'location' => nil,
              'locationLabel' => 'at Port Olisar in orbit around Crusader',
              'rental' => false,
              'buying' => false,
              'selling' => false,
              'storeImage' => @origin600i.listed_at.first.shop.store_image.url,
              'storeImageLarge' => @origin600i.listed_at.first.shop.store_image.large.url,
              'storeImageMedium' => @origin600i.listed_at.first.shop.store_image.medium.url,
              'storeImageSmall' => @origin600i.listed_at.first.shop.store_image.small.url,
              'refineryTerminal' => nil,
              'station' => {
                'name' => 'Port Olisar',
                'slug' => 'port-olisar'
              }
            }
          }, {
            'id' => @origin600i.listed_at.last.id,
            'name' => @origin600i.name,
            'slug' => @origin600i.slug,
            'storeImage' => @origin600i.store_image.url,
            'storeImageLarge' => @origin600i.store_image.large.url,
            'storeImageMedium' => @origin600i.store_image.medium.url,
            'storeImageSmall' => @origin600i.store_image.small.url, 'category' => 'model',
            'subCategory' => 'explorer',
            'subCategoryLabel' => 'Explorer',
            'description' => nil,
            'pricePerUnit' => false,
            'sellPrice' => nil,
            'averageSellPrice' => nil,
            'buyPrice' => nil,
            'averageBuyPrice' => nil,
            'rentalPrice1Day' => nil,
            'averageRentalPrice1Day' => nil,
            'rentalPrice3Days' => nil,
            'averageRentalPrice3Days' => nil,
            'rentalPrice7Days' => nil,
            'averageRentalPrice7Days' => nil,
            'rentalPrice30Days' => nil,
            'averageRentalPrice30Days' => nil,
            'locationLabel' => 'sold at New Deal on Port Olisar',
            'confirmed' => true,
            'commodityItemType' => 'Model',
            'commodityItemId' => @origin600i.id,
            'shop' => {
              'id' => @origin600i.listed_at.last.shop.id,
              'name' => 'New Deal',
              'slug' => 'new-deal',
              'type' => 'ships',
              'typeLabel' => 'Ship Store',
              'stationLabel' => 'at Port Olisar',
              'location' => nil,
              'locationLabel' => 'at Port Olisar in orbit around Crusader',
              'rental' => false,
              'buying' => false,
              'selling' => false,
              'storeImage' => @origin600i.listed_at.last.shop.store_image.url,
              'storeImageLarge' => @origin600i.listed_at.last.shop.store_image.large.url,
              'storeImageMedium' => @origin600i.listed_at.last.shop.store_image.medium.url,
              'storeImageSmall' => @origin600i.listed_at.last.shop.store_image.small.url,
              'refineryTerminal' => nil,
              'station' => { 'name' => 'Port Olisar', 'slug' => 'port-olisar' }
            }
          }],
          'rentalAt' => [],
          'manufacturer' => { 'name' => 'Origin', 'slug' => 'origin', 'code' => nil, 'logo' => nil },
          'loaners' => [{ 'slug' => 'ptv', 'name' => 'PTV' }],
          'docks' => [],
          'createdAt' => @origin600i.created_at&.utc&.iso8601,
          'updatedAt' => @origin600i.updated_at&.utc&.iso8601
        }

        assert_equal expectation, json
      end
    end
  end
end
