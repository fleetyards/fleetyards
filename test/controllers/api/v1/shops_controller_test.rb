# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ShopsControllerTest < ActionController::TestCase
      tests Api::V1::ShopsController

      def setup
        @admin_daymar = shops(:admin_daymar)
        @admin_yela = shops(:admin_yela)
        @admin_olisar = shops(:admin_olisar)
        @dumpers = shops(:dumpers)
        @new_deal = shops(:new_deal)
      end

      test 'should return a single record for show' do
        get :show, params: { station_slug: @new_deal.station.slug, slug: @new_deal.slug }

        assert_response :ok

        json = JSON.parse response.body

        assert_equal @new_deal.name, json['name']
      end

      test 'should return list for index' do
        get :index

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['id'] }

        assert_equal [@admin_daymar.id, @admin_yela.id, @admin_olisar.id, @dumpers.id, @new_deal.id], result
      end

      test 'with session should return a single record for show' do
        data = users(:data)

        sign_in data

        get :show, params: { station_slug: @new_deal.station.slug, slug: @new_deal.slug }

        assert_response :ok

        json = JSON.parse response.body

        assert_equal @new_deal.name, json['name']
      end

      test 'with session should return list for index' do
        data = users(:data)

        sign_in data

        get :index

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['id'] }

        assert_equal [@admin_daymar.id, @admin_yela.id, @admin_olisar.id, @dumpers.id, @new_deal.id], result
      end
    end
  end
end
