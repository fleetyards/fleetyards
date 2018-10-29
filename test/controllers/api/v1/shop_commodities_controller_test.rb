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
          'category' => 'model',
          'subCategory' => 'explorer',
          'subCategoryLabel' => 'Explorer',
          'description' => nil,
          'sellPrice' => nil,
          'buyPrice' => nil,
          'rentPrice' => nil,
          'manufacturer' => {
            'name' => 'Origin',
            'slug' => 'origin',
            'code' => nil,
            'logo' => nil
          },
          'createdAt' => explorer.created_at.to_time.iso8601,
          'updatedAt' => explorer.updated_at.to_time.iso8601
        }, {
          'name' => 'Andromeda',
          'slug' => 'andromeda',
          'storeImage' => andromeda.commodity_item.store_image.url,
          'category' => 'model',
          'subCategory' => 'multi_role',
          'subCategoryLabel' => 'Multi role',
          'description' => nil,
          'sellPrice' => nil,
          'buyPrice' => nil,
          'rentPrice' => nil,
          'manufacturer' => {
            'name' => 'RSI',
            'slug' => 'rsi',
            'code' => nil,
            'logo' => nil
          },
          'createdAt' => andromeda.created_at.to_time.iso8601,
          'updatedAt' => andromeda.updated_at.to_time.iso8601
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
