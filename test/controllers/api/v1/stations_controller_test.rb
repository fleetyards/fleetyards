# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class StationsControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::StationsController

      let(:portolisar) { stations :portolisar }
      let(:corvolex) { stations :corvolex }
      let(:index_result) do
        [{
          'name' => 'Port Olisar',
          'slug' => 'port-olisar',
          'location' => nil,
          'type' => 'spaceport',
          'typeLabel' => 'Spaceport',
          'storeImage' => portolisar.store_image.url,
          'description' => nil,
          'celestialObject' => {
            'name' => 'Crusader',
            'slug' => 'crusader',
            'designation' => '2',
            'storeImage' => portolisar.celestial_object.store_image.url
          },
          'starsystem' => {
            'name' => 'Stanton',
            'slug' => 'stanton',
            'storeImage' => portolisar.starsystem.store_image.url,
            'mapX' => nil,
            'mapY' => nil
          },
          'shops' => [{
            'name' => 'Dumpers Depot',
            'slug' => 'dumpers-depot',
            'type' => 'components',
            'typeLabel' => 'Components Store',
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar.shops.first.store_image.url
          }, {
            'name' => 'New Deal',
            'slug' => 'new-deal',
            'type' => 'ships',
            'typeLabel' => 'Ship Store',
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar.shops.last.store_image.url
          }],
          'docks' => [{
            'size' => 'Large',
            'count' => 1,
            'type' => 'landingpad',
            'typeLabel' => 'Landingpad'
          }, {
            'size' => 'Medium',
            'count' => 1,
            'type' => 'dockingport',
            'typeLabel' => 'Dockingport'
          }],
          'habitations' => [{
            'count' => 1,
            'type' => 'container',
            'typeLabel' => 'Container'
          }],
          'createdAt' => portolisar.created_at.to_time.iso8601,
          'updatedAt' => portolisar.updated_at.to_time.iso8601
        }, {
          'name' => 'Corvolex Shipping Hub',
          'slug' => 'corvolex',
          'location' => nil,
          'type' => 'cargo-station',
          'typeLabel' => 'Cargo Station',
          'storeImage' => corvolex.store_image.url,
          'description' => nil,
          'celestialObject' => {
            'name' => 'Daymar',
            'slug' => 'daymar',
            'designation' => '4',
            'storeImage' => corvolex.celestial_object.store_image.url
          },
          'starsystem' => {
            'name' => 'Stanton',
            'slug' => 'stanton',
            'storeImage' => corvolex.starsystem.store_image.url,
            'mapX' => nil,
            'mapY' => nil
          },
          'shops' => [],
          'docks' => [{
            'size' => 'Small',
            'count' => 1,
            'type' => 'dockingport',
            'typeLabel' => 'Dockingport'
          }],
          'habitations' => [],
          'createdAt' => corvolex.created_at.to_time.iso8601,
          'updatedAt' => corvolex.updated_at.to_time.iso8601
        }]
      end
      let(:show_result) do
        {
          'name' => 'Port Olisar',
          'slug' => 'port-olisar',
          'location' => nil,
          'type' => 'spaceport',
          'typeLabel' => 'Spaceport',
          'description' => nil,
          'storeImage' => portolisar.store_image.url,
          'celestialObject' => {
            'name' => 'Crusader',
            'slug' => 'crusader',
            'designation' => '2',
            'storeImage' => portolisar.celestial_object.store_image.url
          },
          'starsystem' => {
            'name' => 'Stanton',
            'slug' => 'stanton',
            'storeImage' => portolisar.starsystem.store_image.url,
            'mapX' => nil,
            'mapY' => nil
          },
          'shops' => [{
            'name' => 'Dumpers Depot',
            'slug' => 'dumpers-depot',
            'type' => 'components',
            'typeLabel' => 'Components Store',
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar.shops.first.store_image.url,
          }, {
            'name' => 'New Deal',
            'slug' => 'new-deal',
            'type' => 'ships',
            'typeLabel' => 'Ship Store',
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar.shops.last.store_image.url
          }],
          'docks' => [{
            'size' => 'Large',
            'count' => 1,
            'type' => 'landingpad',
            'typeLabel' => 'Landingpad'
          }, {
            'size' => 'Medium',
            'count' => 1,
            'type' => 'dockingport',
            'typeLabel' => 'Dockingport'
          }],
          'habitations' => [{
            'count' => 1,
            'type' => 'container',
            'typeLabel' => 'Container'
          }],
          'images' => [],
          'createdAt' => portolisar.created_at.to_time.iso8601,
          'updatedAt' => portolisar.updated_at.to_time.iso8601
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
          get :show, params: { slug: portolisar.slug }

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
          get :show, params: { slug: portolisar.slug }

          assert_response :ok
          json = JSON.parse response.body

          expected = show_result

          assert_equal expected, json
        end
      end
    end
  end
end
