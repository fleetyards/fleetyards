# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class TradeRoutesControllerTest < ActionController::TestCase
      tests Api::V1::TradeRoutesController

      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s

        @data = users :data

        @gold_yela_daymar = trade_routes :gold_yela_daymar
        @titan_daymar_yela = trade_routes :titan_daymar_yela
        @titan_daymar_olisar = trade_routes :titan_daymar_olisar
      end

      test 'should return list for index' do
        get :index

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['id'] }

        assert_equal [@titan_daymar_yela.id, @titan_daymar_olisar.id, @gold_yela_daymar.id], result
      end

      test 'with session should return list for index' do
        sign_in(@data)

        get :index

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['id'] }

        assert_equal [@titan_daymar_yela.id, @titan_daymar_olisar.id, @gold_yela_daymar.id], result
      end

      test 'with session should return a filtered list for index' do
        sign_in(@data)

        get :index, params: { q: { commodityIn: ['gold'] } }

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['id'] }

        assert_equal [@gold_yela_daymar.id], result
      end

      test 'with session should return an empty list for different commodity' do
        sign_in(@data)

        get :index, params: { q: { commodityIn: ['dilithium'] } }

        assert_response :ok

        json = JSON.parse response.body

        assert_empty json
      end

      test 'with session should return an filtered list for origin' do
        sign_in(@data)

        get :index, params: { q: { originCelestialObjectIn: ['yela'] } }

        assert_response :ok

        json = JSON.parse response.body

        assert_equal 1, json.size
      end

      test 'with session should return an filtered list for destination' do
        sign_in(@data)

        get :index, params: { q: { destinationCelestialObjectIn: ['yela'] } }

        assert_response :ok

        json = JSON.parse response.body

        assert_equal 1, json.size
      end
    end
  end
end
