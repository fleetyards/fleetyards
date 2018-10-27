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
            'name' => 'Port Olisar',
            'slug' => 'port-olisar',
            'location' => nil,
            'type' => 'spaceport',
            'typeLabel' => 'Spaceport',
            'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg',
            'description' => nil,
            'celestialObject' => {
              'name' => 'Crusader',
              'slug' => 'crusader',
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg'
            },
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg',
              'mapX' => nil,
              'mapY' => nil
            },
            'shops' => [{
              'name' => 'Dumpers Depot',
              'slug' => 'dumpers-depot',
              'type' => 'components',
              'typeLabel' => 'Components Store',
              'rental' => false,
              'acquisition' => false,
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg'
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
            'createdAt' => Station.first.created_at.to_time.iso8601,
            'updatedAt' => Station.first.updated_at.to_time.iso8601
          }, {
            'name' => 'Corvolex Shipping Hub',
            'slug' => 'corvolex',
            'location' => nil,
            'type' => 'cargo-station',
            'typeLabel' => 'Cargo Station',
            'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg',
            'description' => nil,
            'celestialObject' => {
              'name' => 'Daymar',
              'slug' => 'daymar',
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg'
            },
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg',
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
            'location' => nil,
            'type' => 'spaceport',
            'typeLabel' => 'Spaceport',
            'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg',
            'description' => nil,
            'celestialObject' => {
              'name' => 'Crusader',
              'slug' => 'crusader',
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg'
            },
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg',
              'mapX' => nil,
              'mapY' => nil
            },
            'shops' => [{
              'name' => 'Dumpers Depot',
              'slug' => 'dumpers-depot',
              'type' => 'components',
              'typeLabel' => 'Components Store',
              'rental' => false,
              'acquisition' => false,
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg'
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
            'name' => 'Port Olisar',
            'slug' => 'port-olisar',
            'location' => nil,
            'type' => 'spaceport',
            'typeLabel' => 'Spaceport',
            'description' => nil,
            'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg',
            'celestialObject' => {
              'name' => 'Crusader',
              'slug' => 'crusader',
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg'
            },
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg',
              'mapX' => nil,
              'mapY' => nil
            },
            'shops' => [{
              'name' => 'Dumpers Depot',
              'slug' => 'dumpers-depot',
              'type' => 'components',
              'typeLabel' => 'Components Store',
              'rental' => false,
              'acquisition' => false,
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg'
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
            'createdAt' => Station.first.created_at.to_time.iso8601,
            'updatedAt' => Station.first.updated_at.to_time.iso8601
          }, {
            'name' => 'Corvolex Shipping Hub',
            'slug' => 'corvolex',
            'location' => nil,
            'type' => 'cargo-station',
            'typeLabel' => 'Cargo Station',
            'description' => nil,
            'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg',
            'celestialObject' => {
              'name' => 'Daymar',
              'slug' => 'daymar',
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg'
            },
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg',
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
            'location' => nil,
            'type' => 'spaceport',
            'typeLabel' => 'Spaceport',
            'description' => nil,
            'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg',
            'celestialObject' => {
              'name' => 'Crusader',
              'slug' => 'crusader',
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg'
            },
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg',
              'mapX' => nil,
              'mapY' => nil
            },
            'shops' => [{
              'name' => 'Dumpers Depot',
              'slug' => 'dumpers-depot',
              'type' => 'components',
              'typeLabel' => 'Components Store',
              'rental' => false,
              'acquisition' => false,
              'storeImage' => 'https://api.fleetyards.net/assets/fallback/store_image-2105ffa73bd0ba272086daec49ef5d4f6fc8e2a47df7a0c2d07b8d016ad61319.jpg'
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

          assert_equal expected, json
        end
      end
    end
  end
end
