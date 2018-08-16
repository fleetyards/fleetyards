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

      describe 'without session' do
        it 'should return list for index' do
          get :index

          assert_response :ok
          json = JSON.parse response.body

          expected = [{
            'name' => 'Corvolex Shipping Hub',
            'slug' => 'corvolex',
            'type' => 'Cargo Station',
            'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-652ef628ba8ccc5a6624faff5888c726b1981954ddc800133b12c299bc400e1f.jpg',
            'planet' => {
              'name' => 'Daymar',
              'slug' => 'daymar'
            },
            'starsystem' => nil,
            'shipCounts' => [{
              'size' => 1,
              'count' => 1,
              'dockType' =>  'Hangar'
            }],
            'createdAt' => Station.first.created_at.to_time.iso8601,
            'updatedAt' => Station.first.updated_at.to_time.iso8601
          }, {
            'name' => 'Port Olisar',
            'slug' => 'port-olisar',
            'type' => 'Hub',
            'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-652ef628ba8ccc5a6624faff5888c726b1981954ddc800133b12c299bc400e1f.jpg',
            'planet' => {
              'name' => 'Crusader',
              'slug' => 'crusader'
            },
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton'
            },
            'shipCounts' => [{
              'size' => 3,
              'count' => 1,
              'dockType' =>  'Dockingport'
            }, {
              'size' => 3,
              'count' => 1,
              'dockType' =>  'Hangar'
            }, {
              'size' => 1,
              'count' => 1,
              'dockType' =>  'Dockingport'
            }, {
              'size' => 1,
              'count' => 1,
              'dockType' =>  'Hangar'
            }],
            'createdAt' => Station.last.created_at.to_time.iso8601,
            'updatedAt' => Station.last.updated_at.to_time.iso8601
          }]

          assert_equal expected, json
        end

        it 'should return a single record for show' do
          get :show, params: { slug: portolisar.slug }

          assert_response :ok
          json = JSON.parse response.body

          expected = {
            'name' => 'Port Olisar',
            'slug' => 'port-olisar',
            'type' => 'Hub',
            'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-652ef628ba8ccc5a6624faff5888c726b1981954ddc800133b12c299bc400e1f.jpg',
            'planet' => {
              'name' => 'Crusader',
              'slug' => 'crusader'
            },
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton'
            },
            'docks' => [{
              'name' => 'Landingpad One',
              'type' => 'Dockingport',
              'maxShipSize' => 3,
              'minShipSize' => 1
            }, {
              'name' => 'Dockingport One',
              'type' => 'Hangar',
              'maxShipSize' => 1,
              'minShipSize' => 1
            }],
            'shipCounts' => [{
              'size' => 3,
              'count' => 1,
              'dockType' =>  'Dockingport'
            }, {
              'size' => 3,
              'count' => 1,
              'dockType' =>  'Hangar'
            }, {
              'size' => 1,
              'count' => 1,
              'dockType' =>  'Dockingport'
            }, {
              'size' => 1,
              'count' => 1,
              'dockType' =>  'Hangar'
            }],
            'shops' => [],
            'images' => [],
            'createdAt' => portolisar.created_at.to_time.iso8601,
            'updatedAt' => portolisar.updated_at.to_time.iso8601
          }

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

          expected = [{
            'name' => 'Corvolex Shipping Hub',
            'slug' => 'corvolex',
            'type' => 'Cargo Station',
            'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-652ef628ba8ccc5a6624faff5888c726b1981954ddc800133b12c299bc400e1f.jpg',
            'planet' => {
              'name' => 'Daymar',
              'slug' => 'daymar'
            },
            'starsystem' => nil,
            'shipCounts' => [{
              'size' => 1,
              'count' => 1,
              'dockType' =>  'Hangar'
            }],
            'createdAt' => Station.first.created_at.to_time.iso8601,
            'updatedAt' => Station.first.updated_at.to_time.iso8601
          }, {
            'name' => 'Port Olisar',
            'slug' => 'port-olisar',
            'type' => 'Hub',
            'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-652ef628ba8ccc5a6624faff5888c726b1981954ddc800133b12c299bc400e1f.jpg',
            'planet' => {
              'name' => 'Crusader',
              'slug' => 'crusader'
            },
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton'
            },
            'shipCounts' => [{
              'size' => 3,
              'count' => 1,
              'dockType' =>  'Dockingport'
            }, {
              'size' => 3,
              'count' => 1,
              'dockType' =>  'Hangar'
            }, {
              'size' => 1,
              'count' => 1,
              'dockType' =>  'Dockingport'
            }, {
              'size' => 1,
              'count' => 1,
              'dockType' =>  'Hangar'
            }],
            'createdAt' => Station.last.created_at.to_time.iso8601,
            'updatedAt' => Station.last.updated_at.to_time.iso8601
          }]

          assert_equal expected, json
        end

        it 'should return a single record for show' do
          get :show, params: { slug: portolisar.slug }

          assert_response :ok
          json = JSON.parse response.body

          expected = {
            'name' => 'Port Olisar',
            'slug' => 'port-olisar',
            'type' => 'Hub',
            'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-652ef628ba8ccc5a6624faff5888c726b1981954ddc800133b12c299bc400e1f.jpg',
            'planet' => {
              'name' => 'Crusader',
              'slug' => 'crusader'
            },
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton'
            },
            'shipCounts' => [{
              'size' => 3,
              'count' => 1,
              'dockType' =>  'Dockingport'
            }, {
              'size' => 3,
              'count' => 1,
              'dockType' =>  'Hangar'
            }, {
              'size' => 1,
              'count' => 1,
              'dockType' =>  'Dockingport'
            }, {
              'size' => 1,
              'count' => 1,
              'dockType' =>  'Hangar'
            }],
            'docks' => [{
              'name' => 'Landingpad One',
              'type' => 'Dockingport',
              'maxShipSize' => 3,
              'minShipSize' => 1
            }, {
              'name' => 'Dockingport One',
              'type' => 'Hangar',
              'maxShipSize' => 1,
              'minShipSize' => 1
            }],
            'shops' => [],
            'images' => [],
            'createdAt' => portolisar.created_at.to_time.iso8601,
            'updatedAt' => portolisar.updated_at.to_time.iso8601
          }

          assert_equal expected, json
        end
      end
    end
  end
end
