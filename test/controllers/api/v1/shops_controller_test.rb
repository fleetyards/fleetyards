# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ShopsControllerTest < ActionController::TestCase
      tests Api::V1::ShopsController

      setup do
        @crusader = celestial_objects(:crusader)
        @new_deal = shops(:new_deal)
      end

      test 'should return a single record for show' do
        get :show, params: { station_slug: show_result['station']['slug'], slug: show_result['slug'] }

        assert_response :ok
        json = JSON.parse response.body

        assert_equal show_result, json
      end

      test 'should return list for index' do
        get :index

        assert_response :ok

        json = JSON.parse response.body
        result_ids = json.map { |item| item['id'] }

        assert_equal index_result_ids, result_ids
      end

      test 'with session should return a single record for show' do
        data = users(:data)

        sign_in data

        get :show, params: { station_slug: show_result['station']['slug'], slug: show_result['slug'] }

        assert_response :ok
        json = JSON.parse response.body

        assert_equal show_result, json
      end

      test 'with session should return list for index' do
        data = users(:data)

        sign_in data

        get :index

        assert_response :o

        json = JSON.parse response.body
        result_ids = json.map { |item| item['id'] }

        assert_equal index_result_ids, result_ids
      end

      # rubocop:disable Metrics/MethodLength
      def show_result
        @show_result ||= {
          'id' => @new_deal.id,
          'name' => 'New Deal',
          'slug' => 'new-deal',
          'type' => 'ships',
          'typeLabel' => 'Ship Store',
          'stationLabel' => @new_deal.station_label,
          'location' => @new_deal.location,
          'locationLabel' => @new_deal.location_label,
          'rental' => false,
          'buying' => false,
          'selling' => false,
          'storeImage' => @new_deal.store_image.url,
          'storeImageLarge' => @new_deal.store_image.large.url,
          'storeImageMedium' => @new_deal.store_image.medium.url,
          'storeImageSmall' => @new_deal.store_image.small.url,
          'refineryTerminal' => nil,
          'station' => {
            'name' => 'Port Olisar',
            'slug' => 'port-olisar'
          },
          'celestialObject' => {
            'name' => 'Crusader',
            'slug' => 'crusader',
            'type' => nil,
            'designation' => '2',
            'storeImage' => @crusader.store_image.url,
            'storeImageLarge' => @crusader.store_image.large.url,
            'storeImageMedium' => @crusader.store_image.medium.url,
            'storeImageSmall' => @crusader.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil,
            'locationLabel' => @crusader.location_label,
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => @crusader.starsystem.store_image.url,
              'storeImageLarge' => @crusader.starsystem.store_image.large.url,
              'storeImageMedium' => @crusader.starsystem.store_image.medium.url,
              'storeImageSmall' => @crusader.starsystem.store_image.small.url,
              'mapX' => nil,
              'mapY' => nil,
              'description' => nil,
              'type' => nil,
              'size' => nil,
              'population' => nil,
              'economy' => nil,
              'danger' => nil,
              'status' => nil,
              'locationLabel' => @crusader.starsystem.location_label,
            }
          },
          'createdAt' => @new_deal.created_at.utc.iso8601,
          'updatedAt' => @new_deal.updated_at.utc.iso8601
        }
      end
      # rubocop:enable Metrics/MethodLength

      def index_result_ids
        @index_result_ids ||= begin
          admin_daymar = shops(:admin_daymar)
          admin_yela = shops(:admin_yela)
          admin_olisar = shops(:admin_olisar)
          dumpers = shops(:dumpers)
          new_deal = shops(:new_deal)

          [admin_daymar.id, admin_yela.id, admin_olisar.id, dumpers.id, new_deal.id]
        end
      end
    end
  end
end
