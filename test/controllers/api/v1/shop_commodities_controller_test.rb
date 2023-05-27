# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class ShopCommoditiesControllerTest < ActionDispatch::IntegrationTest
      let(:new_deal) { shops :new_deal }

      def setup
        Searchkick.enable_callbacks
      end

      def teardown
        Searchkick.disable_callbacks
      end

      describe "without session" do
        it "should return list for index" do
          VCR.use_cassette("shop_commodities_index") do
            get "/api/v1/stations/#{new_deal.station.slug}/shops/#{new_deal.slug}/commodities", as: :json

            assert_response :ok
            json = JSON.parse response.body

            assert_equal 2, json.size
          end
        end
      end

      describe "with session" do
        let(:data) { users :data }

        before do
          sign_in data
        end

        it "should return list for index" do
          VCR.use_cassette("shop_commodities_index") do
            get "/api/v1/stations/#{new_deal.station.slug}/shops/#{new_deal.slug}/commodities", as: :json

            assert_response :ok
            json = JSON.parse response.body

            assert_equal 2, json.size
          end
        end
      end
    end
  end
end
