# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ShopCommoditiesControllerTest < ActionController::TestCase
      tests Api::V1::ShopCommoditiesController

      def setup
        Searchkick.enable_callbacks

        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      def teardown
        Searchkick.disable_callbacks
      end

      test 'should return list for index' do
        new_deal = shops :new_deal

        VCR.use_cassette('shop_commodities_index') do
          get :index, params: { station_slug: new_deal.station.slug, shop_slug: new_deal.slug }

          assert_response :ok

          json = JSON.parse response.body
          result = json.map { |item| item['id'] }

          expectation = new_deal.shop_commodities.pluck(:id)

          assert_equal expectation, result
        end
      end

      test 'with session should return list for index' do
        sign_in(users(:data))

        new_deal = shops :new_deal

        VCR.use_cassette('shop_commodities_index') do
          get :index, params: { station_slug: new_deal.station.slug, shop_slug: new_deal.slug }

          assert_response :ok

          json = JSON.parse response.body
          result = json.map { |item| item['id'] }

          expectation = new_deal.shop_commodities.pluck(:id)

          assert_equal expectation, result
        end
      end
    end
  end
end
