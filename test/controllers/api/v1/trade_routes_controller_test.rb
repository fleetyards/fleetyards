# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class TradeRoutesControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::TradeRoutesController

      let(:gold_yela_daymar) { trade_routes :gold_yela_daymar }
      let(:titan_daymar_yela) { trade_routes :titan_daymar_yela }
      let(:titan_daymar_olisar) { trade_routes :titan_daymar_olisar }
      let(:index_result) do
        [{
          'id' => titan_daymar_yela.id,
          'origin' => {
            'name' => 'ArcCorp 001',
            'slug' => 'arccorp',
            'type' => 'outpost',
            'locationLabel' => 'on Daymar',
            'shop' => 'Admin Office',
            'shopSlug' => 'admin-office',
            'planet' => 'Daymar',
            'planetSlug' => 'daymar',
            'starsystem' => 'Stanton',
            'starsystemSlug' => 'stanton'
          },
          'destination' => {
            'name' => 'ArcCorp 002',
            'slug' => 'arccorp',
            'type' => 'outpost',
            'locationLabel' => 'on Yela',
            'shop' => 'Admin Office',
            'shopSlug' => 'admin-office',
            'planet' => 'Yela',
            'planetSlug' => 'yela',
            'starsystem' => 'Stanton',
            'starsystemSlug' => 'stanton'
          },
          'commodity' => {
            'name' => 'Titan',
            'slug' => 'titan',
            'type' => nil
          },
          'buyPrice' => '10.0',
          'averageBuyPrice' => '10.0',
          'sellPrice' => '20.0',
          'averageSellPrice' => '20.0',
          'profitPerUnit' => '10.0',
          'averageProfitPerUnit' => '10.0',
          'profitPerUnitPercent' => '50.0',
          'averageProfitPerUnitPercent' => '50.0',
          'createdAt' => titan_daymar_yela.created_at.utc.iso8601,
          'updatedAt' => titan_daymar_yela.updated_at.utc.iso8601
        }, {
          'id' => titan_daymar_olisar.id,
          'origin' => {
            'name' => 'ArcCorp 001',
            'slug' => 'arccorp',
            'type' => 'outpost',
            'locationLabel' => 'on Daymar',
            'shop' => 'Admin Office',
            'shopSlug' => 'admin-office',
            'planet' => 'Daymar',
            'planetSlug' => 'daymar',
            'starsystem' => 'Stanton',
            'starsystemSlug' => 'stanton'
          },
          'destination' => {
            'name' => 'Port Olisar',
            'slug' => 'port-olisar',
            'type' => 'station',
            'locationLabel' => 'in orbit around Crusader',
            'shop' => 'Admin Office',
            'shopSlug' => 'admin-office',
            'planet' => 'Crusader',
            'planetSlug' => 'crusader',
            'starsystem' => 'Stanton',
            'starsystemSlug' => 'stanton'
          },
          'commodity' => {
            'name' => 'Titan',
            'slug' => 'titan',
            'type' => nil
          },
          'buyPrice' => '10.0',
          'averageBuyPrice' => '10.0',
          'sellPrice' => '17.0',
          'averageSellPrice' => '17.0',
          'profitPerUnit' => '7.0',
          'averageProfitPerUnit' => '7.0',
          'profitPerUnitPercent' => '70.0',
          'averageProfitPerUnitPercent' => '70.0',
          'createdAt' => titan_daymar_olisar.created_at.utc.iso8601,
          'updatedAt' => titan_daymar_olisar.updated_at.utc.iso8601
        }, {
          'id' => gold_yela_daymar.id,
          'origin' => {
            'name' => 'ArcCorp 002',
            'slug' => 'arccorp',
            'type' => 'outpost',
            'locationLabel' => 'on Yela',
            'shop' => 'Admin Office',
            'shopSlug' => 'admin-office',
            'planet' => 'Yela',
            'planetSlug' => 'yela',
            'starsystem' => 'Stanton',
            'starsystemSlug' => 'stanton'
          },
          'destination' => {
            'name' => 'ArcCorp 001',
            'slug' => 'arccorp',
            'type' => 'outpost',
            'locationLabel' => 'on Daymar',
            'shop' => 'Admin Office',
            'shopSlug' => 'admin-office',
            'planet' => 'Daymar',
            'planetSlug' => 'daymar',
            'starsystem' => 'Stanton',
            'starsystemSlug' => 'stanton'
          },
          'commodity' => {
            'name' => 'Gold',
            'slug' => 'gold',
            'type' => nil
          },
          'buyPrice' => '5.0',
          'averageBuyPrice' => '5.0',
          'sellPrice' => '10.0',
          'averageSellPrice' => '10.0',
          'profitPerUnit' => '5.0',
          'averageProfitPerUnit' => '5.0',
          'profitPerUnitPercent' => '50.0',
          'averageProfitPerUnitPercent' => '50.0',
          'createdAt' => gold_yela_daymar.created_at.utc.iso8601,
          'updatedAt' => gold_yela_daymar.updated_at.utc.iso8601
        }]
      end
      let(:filtered_index_result) do
        [{
          'id' => gold_yela_daymar.id,
          'origin' => {
            'name' => 'ArcCorp 002',
            'slug' => 'arccorp',
            'type' => 'outpost',
            'locationLabel' => 'on Yela',
            'shop' => 'Admin Office',
            'shopSlug' => 'admin-office',
            'planet' => 'Yela',
            'planetSlug' => 'yela',
            'starsystem' => 'Stanton',
            'starsystemSlug' => 'stanton'
          },
          'destination' => {
            'name' => 'ArcCorp 001',
            'slug' => 'arccorp',
            'type' => 'outpost',
            'locationLabel' => 'on Daymar',
            'shop' => 'Admin Office',
            'shopSlug' => 'admin-office',
            'planet' => 'Daymar',
            'planetSlug' => 'daymar',
            'starsystem' => 'Stanton',
            'starsystemSlug' => 'stanton'
          },
          'commodity' => {
            'name' => 'Gold',
            'slug' => 'gold',
            'type' => nil
          },
          'buyPrice' => '5.0',
          'averageBuyPrice' => '5.0',
          'sellPrice' => '10.0',
          'averageSellPrice' => '10.0',
          'profitPerUnit' => '5.0',
          'averageProfitPerUnit' => '5.0',
          'profitPerUnitPercent' => '50.0',
          'averageProfitPerUnitPercent' => '50.0',
          'createdAt' => gold_yela_daymar.created_at.utc.iso8601,
          'updatedAt' => gold_yela_daymar.updated_at.utc.iso8601
        }]
      end

      describe 'without session' do
        it 'should return list for index' do
          get :index

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
          get :index

          assert_response :ok
          json = JSON.parse response.body

          assert_equal index_result, json
        end

        it 'should return a filtered list for index' do
          get :index, params: { q: { commodityIn: ['gold'] } }

          assert_response :ok
          json = JSON.parse response.body

          assert_equal filtered_index_result, json
        end

        it 'should return an empty list for different commodity' do
          get :index, params: { q: { commodityIn: ['dilithium'] } }

          assert_response :ok
          json = JSON.parse response.body

          assert_empty json
        end

        it 'should return an filtered list for planet' do
          get :index, params: { q: { originCelestialObjectIn: ['yela'] } }

          assert_response :ok
          json = JSON.parse response.body

          assert_equal 1, json.size
        end

        it 'should return an filtered list for planet' do
          get :index, params: { q: { destinationCelestialObjectIn: ['yela'] } }

          assert_response :ok
          json = JSON.parse response.body

          assert_equal 1, json.size
        end
      end
    end
  end
end
