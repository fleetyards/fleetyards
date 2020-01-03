# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ModelsControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::ModelsController

      it 'should return list for index' do
        get :index

        assert_response :ok
        json = JSON.parse response.body

        expected = [{
          'id' => Model.first.id,
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
          'storeImage' => Model.first.store_image.url,
          'storeImageMedium' => Model.first.store_image.medium.url,
          'storeImageSmall' => Model.first.store_image.small.url,
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
          'lastUpdatedAt' => Model.first.last_updated_at&.utc&.iso8601,
          'lastUpdatedAtLabel' => (I18n.l(Model.first.last_updated_at&.utc, format: :label) if Model.first.last_updated_at.present?),
          'manufacturer' => {
            'name' => 'Origin',
            'slug' => 'origin',
            'code' => nil,
            'logo' => nil
          },
          'createdAt' => Model.first.created_at.utc.iso8601,
          'updatedAt' => Model.first.updated_at.utc.iso8601
        }, {
          'id' => Model.last.id,
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
          'storeImage' => Model.last.store_image.url,
          'storeImageMedium' => Model.last.store_image.medium.url,
          'storeImageSmall' => Model.last.store_image.small.url,
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
          'lastUpdatedAt' => Model.last.last_updated_at&.utc&.iso8601,
          'lastUpdatedAtLabel' => (I18n.l(Model.last.last_updated_at&.utc, format: :label) if Model.last.last_updated_at.present?),
          'manufacturer' => {
            'name' => 'RSI',
            'slug' => 'rsi',
            'code' => nil,
            'logo' => nil
          },
          'createdAt' => Model.last.created_at.utc.iso8601,
          'updatedAt' => Model.last.updated_at.utc.iso8601
        }]
        assert_equal expected, json
      end

      it 'should be able to filter the list' do
        get :index, params: { q: '{ "nameCont": "Andromeda" }' }

        assert_response :ok
        json = JSON.parse response.body

        assert_equal 1, json.count
        assert_equal 'Andromeda', json.first['name']
      end

      it 'should be able to reduce per page size' do
        get :index, params: { perPage: '1' }

        assert_response :ok
        json = JSON.parse response.body

        assert_equal 1, json.count
      end
    end
  end
end
