# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class CelestialObjectsControllerTest < ActionController::TestCase
      tests Api::V1::CelestialObjectsController

      setup do
        @data = users(:data)

        @crusader = celestial_objects(:crusader)
        @hurston = celestial_objects(:hurston)
        @yela = celestial_objects(:yela)
        @daymar = celestial_objects(:daymar)
      end

      test 'should return list for index' do
        get :index

        assert_response :ok

        json = JSON.parse response.body
        result_slugs = json.map { |item| item['slug'] }

        assert_equal [@hurston.slug, @crusader.slug, @yela.slug, @daymar.slug], result_slugs
      end

      test 'should return a single record for show' do
        get :show, params: { slug: @crusader.slug }

        assert_response :ok
        json = JSON.parse response.body

        assert_equal show_result, json
      end

      test 'with session should return list for index' do
        sign_in(@data)

        get :index

        assert_response :ok

        json = JSON.parse response.body
        result_slugs = json.map { |item| item['slug'] }

        assert_equal [@hurston.slug, @crusader.slug, @yela.slug, @daymar.slug], result_slugs
      end

      test 'with session should return a single record for show' do
        sign_in(@data)

        get :show, params: { slug: @crusader.slug }

        assert_response :ok
        json = JSON.parse response.body

        assert_equal show_result, json
      end

      # rubocop:disable Metrics/MethodLength
      def show_result
        {
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
          },
          'moons' => [{
            'name' => 'Yela',
            'slug' => 'yela',
            'type' => nil,
            'designation' => '3',
            'storeImage' => @crusader.moons.first.store_image.url,
            'storeImageLarge' => @crusader.moons.first.store_image.large.url,
            'storeImageMedium' => @crusader.moons.first.store_image.medium.url,
            'storeImageSmall' => @crusader.moons.first.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil,
            'locationLabel' => @crusader.moons.first.location_label,
            'parent' => {
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
              },
            },
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
            },
          }, {
            'name' => 'Daymar',
            'slug' => 'daymar',
            'type' => nil,
            'designation' => '4',
            'storeImage' => @crusader.moons.last.store_image.url,
            'storeImageLarge' => @crusader.moons.last.store_image.large.url,
            'storeImageMedium' => @crusader.moons.last.store_image.medium.url,
            'storeImageSmall' => @crusader.moons.last.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil,
            'locationLabel' => @crusader.moons.last.location_label,
            'parent' => {
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
              },
            },
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
            },
          }],
          'createdAt' => @crusader.created_at.utc.iso8601,
          'updatedAt' => @crusader.updated_at.utc.iso8601
        }
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
