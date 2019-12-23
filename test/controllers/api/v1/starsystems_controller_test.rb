# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class StarsystemsControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::StarsystemsController

      let(:stanton) { starsystems :stanton }
      let(:oberon) { starsystems :oberon }
      let(:index_result) do
        [{
          'name' => 'Oberon',
          'slug' => 'oberon',
          'storeImage' => oberon.store_image.url,
          'storeImageMedium' => oberon.store_image.medium.url,
          'storeImageSmall' => oberon.store_image.small.url,
          'mapX' => nil,
          'mapY' => nil,
          'description' => nil,
          'type' => nil,
          'size' => nil,
          'population' => nil,
          'economy' => nil,
          'danger' => nil,
          'status' => nil,
          'locationLabel' => oberon.location_label,
          'celestialObjects' => [],
          'createdAt' => oberon.created_at.utc.iso8601,
          'updatedAt' => oberon.updated_at.utc.iso8601
        }, {
          'name' => 'Stanton',
          'slug' => 'stanton',
          'storeImage' => stanton.store_image.url,
          'storeImageMedium' => stanton.store_image.medium.url,
          'storeImageSmall' => stanton.store_image.small.url,
          'description' => nil,
          'mapX' => nil,
          'mapY' => nil,
          'type' => nil,
          'size' => nil,
          'population' => nil,
          'economy' => nil,
          'danger' => nil,
          'status' => nil,
          'locationLabel' => stanton.location_label,
          'celestialObjects' => [{
            'name' => 'Hurston',
            'slug' => 'hurston',
            'type' => nil,
            'designation' => '1',
            'storeImage' => stanton.celestial_objects.first.store_image.url,
            'storeImageMedium' => stanton.celestial_objects.first.store_image.medium.url,
            'storeImageSmall' => stanton.celestial_objects.first.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil,
            'locationLabel' => stanton.celestial_objects.first.location_label,
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => stanton.store_image.url,
              'storeImageMedium' => stanton.store_image.medium.url,
              'storeImageSmall' => stanton.store_image.small.url,
              'mapX' => nil,
              'mapY' => nil,
              'description' => nil,
              'type' => nil,
              'size' => nil,
              'population' => nil,
              'economy' => nil,
              'danger' => nil,
              'status' => nil,
              'locationLabel' => stanton.location_label,
            },
          }, {
            'name' => 'Crusader',
            'slug' => 'crusader',
            'type' => nil,
            'designation' => '2',
            'storeImage' => stanton.celestial_objects.last.store_image.url,
            'storeImageMedium' => stanton.celestial_objects.last.store_image.medium.url,
            'storeImageSmall' => stanton.celestial_objects.last.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil,
            'locationLabel' => stanton.celestial_objects.last.location_label,
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => stanton.store_image.url,
              'storeImageMedium' => stanton.store_image.medium.url,
              'storeImageSmall' => stanton.store_image.small.url,
              'mapX' => nil,
              'mapY' => nil,
              'description' => nil,
              'type' => nil,
              'size' => nil,
              'population' => nil,
              'economy' => nil,
              'danger' => nil,
              'status' => nil,
              'locationLabel' => stanton.location_label,
            },
          }],
          'createdAt' => stanton.created_at.utc.iso8601,
          'updatedAt' => stanton.updated_at.utc.iso8601
        }]
      end
      let(:show_result) do
        {
          'name' => 'Stanton',
          'slug' => 'stanton',
          'storeImage' => stanton.store_image.url,
          'storeImageMedium' => stanton.store_image.medium.url,
          'storeImageSmall' => stanton.store_image.small.url,
          'mapX' => nil,
          'mapY' => nil,
          'description' => nil,
          'type' => nil,
          'size' => nil,
          'population' => nil,
          'economy' => nil,
          'danger' => nil,
          'status' => nil,
          'locationLabel' => stanton.location_label,
          'celestialObjects' => [{
            'name' => 'Hurston',
            'slug' => 'hurston',
            'type' => nil,
            'designation' => '1',
            'storeImage' => stanton.celestial_objects.first.store_image.url,
            'storeImageMedium' => stanton.celestial_objects.first.store_image.medium.url,
            'storeImageSmall' => stanton.celestial_objects.first.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil,
            'locationLabel' => stanton.celestial_objects.first.location_label,
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => stanton.store_image.url,
              'storeImageMedium' => stanton.store_image.medium.url,
              'storeImageSmall' => stanton.store_image.small.url,
              'mapX' => nil,
              'mapY' => nil,
              'description' => nil,
              'type' => nil,
              'size' => nil,
              'population' => nil,
              'economy' => nil,
              'danger' => nil,
              'status' => nil,
              'locationLabel' => stanton.location_label,
            },
          }, {
            'name' => 'Crusader',
            'slug' => 'crusader',
            'type' => nil,
            'designation' => '2',
            'storeImage' => stanton.celestial_objects.last.store_image.url,
            'storeImageMedium' => stanton.celestial_objects.last.store_image.medium.url,
            'storeImageSmall' => stanton.celestial_objects.last.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil,
            'locationLabel' => stanton.celestial_objects.last.location_label,
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => stanton.store_image.url,
              'storeImageMedium' => stanton.store_image.medium.url,
              'storeImageSmall' => stanton.store_image.small.url,
              'mapX' => nil,
              'mapY' => nil,
              'description' => nil,
              'type' => nil,
              'size' => nil,
              'population' => nil,
              'economy' => nil,
              'danger' => nil,
              'status' => nil,
              'locationLabel' => stanton.location_label,
            },
          }],
          'createdAt' => stanton.created_at.utc.iso8601,
          'updatedAt' => stanton.updated_at.utc.iso8601
        }
      end

      describe 'without session' do
        it 'should return list for index' do
          get :index

          assert_response :ok
          json = JSON.parse response.body

          assert_equal index_result, json
        end

        it 'should return a single record for show' do
          get :show, params: { slug: stanton.slug }

          assert_response :ok
          json = JSON.parse response.body

          assert_equal show_result, json
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

        it 'should return a single record for show' do
          get :show, params: { slug: stanton.slug }

          assert_response :ok
          json = JSON.parse response.body

          assert_equal show_result, json
        end
      end
    end
  end
end
