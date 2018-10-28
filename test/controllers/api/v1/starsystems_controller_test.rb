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
          'mapX' => nil,
          'mapY' => nil,
          'celestialObjects' => [],
          'createdAt' => oberon.created_at.to_time.iso8601,
          'updatedAt' => oberon.updated_at.to_time.iso8601
        }, {
          'name' => 'Stanton',
          'slug' => 'stanton',
          'storeImage' => stanton.store_image.url,
          'mapX' => nil,
          'mapY' => nil,
          'celestialObjects' => [{
            'name' => 'Hurston',
            'slug' => 'hurston',
            'designation' => nil,
            'storeImage' => stanton.celestial_objects.first.store_image.url
          }, {
            'name' => 'Crusader',
            'slug' => 'crusader',
            'designation' => nil,
            'storeImage' => stanton.celestial_objects.last.store_image.url
          }],
          'createdAt' => stanton.created_at.to_time.iso8601,
          'updatedAt' => stanton.updated_at.to_time.iso8601
        }]
      end
      let(:show_result) do
        {
          'name' => 'Stanton',
          'slug' => 'stanton',
          'storeImage' => stanton.store_image.url,
          'mapX' => nil,
          'mapY' => nil,
          'celestialObjects' => [{
            'name' => 'Hurston',
            'slug' => 'hurston',
            'designation' => nil,
            'storeImage' => stanton.celestial_objects.first.store_image.url
          }, {
            'name' => 'Crusader',
            'slug' => 'crusader',
            'designation' => nil,
            'storeImage' => stanton.celestial_objects.last.store_image.url
          }],
          'createdAt' => stanton.created_at.to_time.iso8601,
          'updatedAt' => stanton.updated_at.to_time.iso8601
        }
      end

      describe 'without session' do
        it 'should return list for index' do
          get :index

          assert_response :ok
          json = JSON.parse response.body

          expected = index_result

          assert_equal expected, json
        end

        it 'should return a single record for show' do
          get :show, params: { slug: stanton.slug }

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
          get :index

          assert_response :ok
          json = JSON.parse response.body

          expected = index_result

          assert_equal expected, json
        end

        it 'should return a single record for show' do
          get :show, params: { slug: stanton.slug }

          assert_response :ok
          json = JSON.parse response.body

          expected = show_result

          assert_equal expected, json
        end
      end
    end
  end
end
