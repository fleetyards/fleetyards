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
      let(:show_result) do
        [{
          'sellPrice' => nil,
          'buyPrice' => nil,
          'rentPrice' => nil,
          'commodityItem' => {
            'name' => '600i',
            'slug' => '600i',
            'description' => nil,
            'storeImage' => explorer.commodity_item.store_image.url,
            'type' => 'Model'
          },
          'createdAt' => explorer.created_at.to_time.iso8601,
          'updatedAt' => explorer.updated_at.to_time.iso8601
        }, {
          'sellPrice' => nil,
          'buyPrice' => nil,
          'rentPrice' => nil,
          'commodityItem' => {
            'name' => 'Andromeda',
            'slug' => 'andromeda',
            'description' => nil,
            'storeImage' => andromeda.commodity_item.store_image.url,
            'type' => 'Model'
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

          expected = show_result

          assert_equal expected, json
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

          expected = show_result

          assert_equal expected, json
        end
      end
    end
  end
end
