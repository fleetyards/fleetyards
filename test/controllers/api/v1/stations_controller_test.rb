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

      let(:crusader) { celestial_objects :crusader }
      let(:yela) { celestial_objects :yela }
      let(:daymar) { celestial_objects :daymar }
      let(:portolisar) { stations :portolisar }
      let(:corvolex) { stations :corvolex }
      let(:arccorp_daymar) { stations :arccorp_daymar }
      let(:arccorp_yela) { stations :arccorp_yela }
      let(:index_result) do
        [{
          'name' => 'ArcCorp',
          'slug' => 'arccorp',
          'location' => nil,
          'locationLabel' => arccorp_yela.location_label,
          'type' => 'outpost',
          'typeLabel' => 'Outpost',
          'storeImage' => arccorp_yela.store_image.url,
          'storeImageMedium' => arccorp_yela.store_image.medium.url,
          'storeImageSmall' => arccorp_yela.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
          'hasImages' => false,
          'shopListLabel' => arccorp_yela.shop_list_label,
          'habitationCounts' => [],
          'dockCounts' => [],
          'celestialObject' => {
            'name' => 'Yela',
            'slug' => 'yela',
            'type' => nil,
            'designation' => '3',
            'storeImage' => yela.store_image.url,
            'storeImageMedium' => yela.store_image.medium.url,
            'storeImageSmall' => yela.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil,
            'locationLabel' => yela.location_label,
            'parent' => {
              'name' => 'Crusader',
              'slug' => 'crusader',
              'type' => nil,
              'designation' => '2',
              'storeImage' => crusader.store_image.url,
              'storeImageMedium' => crusader.store_image.medium.url,
              'storeImageSmall' => crusader.store_image.small.url,
              'description' => nil,
              'habitable' => nil,
              'fairchanceact' => nil,
              'subType' => nil,
              'size' => nil,
              'danger' => nil,
              'economy' => nil,
              'population' => nil,
              'locationLabel' => crusader.location_label,
              'starsystem' => {
                'name' => 'Stanton',
                'slug' => 'stanton',
                'storeImage' => crusader.starsystem.store_image.url,
                'storeImageMedium' => crusader.starsystem.store_image.medium.url,
                'storeImageSmall' => crusader.starsystem.store_image.small.url,
                'mapX' => nil,
                'mapY' => nil,
                'description' => nil,
                'type' => nil,
                'size' => nil,
                'population' => nil,
                'economy' => nil,
                'danger' => nil,
                'status' => nil,
                'locationLabel' => crusader.starsystem.location_label,
              },
            },
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => crusader.starsystem.store_image.url,
              'storeImageMedium' => crusader.starsystem.store_image.medium.url,
              'storeImageSmall' => crusader.starsystem.store_image.small.url,
              'description' => nil,
              'mapX' => nil,
              'mapY' => nil,
              'type' => nil,
              'size' => nil,
              'population' => nil,
              'economy' => nil,
              'danger' => nil,
              'status' => nil,
              'locationLabel' => crusader.starsystem.location_label,
            },
          },
          'createdAt' => arccorp_yela.created_at.utc.iso8601,
          'updatedAt' => arccorp_yela.updated_at.utc.iso8601
        }, {
          'name' => 'ArcCorp',
          'slug' => 'arccorp',
          'location' => nil,
          'locationLabel' => arccorp_daymar.location_label,
          'type' => 'outpost',
          'typeLabel' => 'Outpost',
          'storeImage' => arccorp_daymar.store_image.url,
          'storeImageMedium' => arccorp_daymar.store_image.medium.url,
          'storeImageSmall' => arccorp_daymar.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
          'hasImages' => false,
          'shopListLabel' => arccorp_daymar.shop_list_label,
          'habitationCounts' => [],
          'dockCounts' => [],
          'celestialObject' => {
            'name' => 'Daymar',
            'slug' => 'daymar',
            'type' => nil,
            'designation' => '4',
            'storeImage' => daymar.store_image.url,
            'storeImageMedium' => daymar.store_image.medium.url,
            'storeImageSmall' => daymar.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil,
            'locationLabel' => daymar.location_label,
            'parent' => {
              'name' => 'Crusader',
              'slug' => 'crusader',
              'type' => nil,
              'designation' => '2',
              'storeImage' => crusader.store_image.url,
              'storeImageMedium' => crusader.store_image.medium.url,
              'storeImageSmall' => crusader.store_image.small.url,
              'description' => nil,
              'habitable' => nil,
              'fairchanceact' => nil,
              'subType' => nil,
              'size' => nil,
              'danger' => nil,
              'economy' => nil,
              'population' => nil,
              'locationLabel' => crusader.location_label,
              'starsystem' => {
                'name' => 'Stanton',
                'slug' => 'stanton',
                'storeImage' => crusader.starsystem.store_image.url,
                'storeImageMedium' => crusader.starsystem.store_image.medium.url,
                'storeImageSmall' => crusader.starsystem.store_image.small.url,
                'mapX' => nil,
                'mapY' => nil,
                'description' => nil,
                'type' => nil,
                'size' => nil,
                'population' => nil,
                'economy' => nil,
                'danger' => nil,
                'status' => nil,
                'locationLabel' => crusader.starsystem.location_label,
              },
            },
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => crusader.starsystem.store_image.url,
              'storeImageMedium' => crusader.starsystem.store_image.medium.url,
              'storeImageSmall' => crusader.starsystem.store_image.small.url,
              'mapX' => nil,
              'mapY' => nil,
              'description' => nil,
              'type' => nil,
              'size' => nil,
              'population' => nil,
              'economy' => nil,
              'danger' => nil,
              'status' => nil,
              'locationLabel' => crusader.starsystem.location_label,
            },
          },
          'createdAt' => arccorp_daymar.created_at.utc.iso8601,
          'updatedAt' => arccorp_daymar.updated_at.utc.iso8601
        }, {
          'name' => 'Corvolex Shipping Hub',
          'slug' => 'corvolex',
          'location' => nil,
          'locationLabel' => corvolex.location_label,
          'type' => 'cargo-station',
          'typeLabel' => 'Cargo Station',
          'storeImage' => corvolex.store_image.url,
          'storeImageMedium' => corvolex.store_image.medium.url,
          'storeImageSmall' => corvolex.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
          'hasImages' => false,
          'shopListLabel' => corvolex.shop_list_label,
          'habitationCounts' => [],
          'dockCounts' => [{
            'size' => 'Small',
            'count' => 1,
            'type' => 'dockingport',
            'typeLabel' => 'Dockingport'
          }],
          'celestialObject' => {
            'name' => 'Daymar',
            'slug' => 'daymar',
            'type' => nil,
            'designation' => '4',
            'storeImage' => daymar.store_image.url,
            'storeImageMedium' => daymar.store_image.medium.url,
            'storeImageSmall' => daymar.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil,
            'locationLabel' => daymar.location_label,
            'parent' => {
              'name' => 'Crusader',
              'slug' => 'crusader',
              'type' => nil,
              'designation' => '2',
              'storeImage' => crusader.store_image.url,
              'storeImageMedium' => crusader.store_image.medium.url,
              'storeImageSmall' => crusader.store_image.small.url,
              'description' => nil,
              'habitable' => nil,
              'fairchanceact' => nil,
              'subType' => nil,
              'size' => nil,
              'danger' => nil,
              'economy' => nil,
              'population' => nil,
              'locationLabel' => crusader.location_label,
              'starsystem' => {
                'name' => 'Stanton',
                'slug' => 'stanton',
                'storeImage' => crusader.starsystem.store_image.url,
                'storeImageMedium' => crusader.starsystem.store_image.medium.url,
                'storeImageSmall' => crusader.starsystem.store_image.small.url,
                'mapX' => nil,
                'mapY' => nil,
                'description' => nil,
                'type' => nil,
                'size' => nil,
                'population' => nil,
                'economy' => nil,
                'danger' => nil,
                'status' => nil,
                'locationLabel' => crusader.starsystem.location_label,
              },
            },
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => crusader.starsystem.store_image.url,
              'storeImageMedium' => crusader.starsystem.store_image.medium.url,
              'storeImageSmall' => crusader.starsystem.store_image.small.url,
              'mapX' => nil,
              'mapY' => nil,
              'description' => nil,
              'type' => nil,
              'size' => nil,
              'population' => nil,
              'economy' => nil,
              'danger' => nil,
              'status' => nil,
              'locationLabel' => crusader.starsystem.location_label,
            },
          },
          'createdAt' => corvolex.created_at.utc.iso8601,
          'updatedAt' => corvolex.updated_at.utc.iso8601
        }, {
          'name' => 'Port Olisar',
          'slug' => 'port-olisar',
          'location' => nil,
          'locationLabel' => portolisar.location_label,
          'type' => 'hub',
          'typeLabel' => 'Hub',
          'storeImage' => portolisar.store_image.url,
          'storeImageMedium' => portolisar.store_image.medium.url,
          'storeImageSmall' => portolisar.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
          'hasImages' => false,
          'shopListLabel' => portolisar.shop_list_label,
          'habitationCounts' => [{
            'count' => 1,
            'type' => 'container',
            'typeLabel' => 'Container'
          }],
          'dockCounts' => [{
            'size' => 'Medium',
            'count' => 1,
            'type' => 'dockingport',
            'typeLabel' => 'Dockingport'
          }, {
            'size' => 'Large',
            'count' => 2,
            'type' => 'landingpad',
            'typeLabel' => 'Landingpad'
          }],
          'celestialObject' => {
            'name' => 'Crusader',
            'slug' => 'crusader',
            'type' => nil,
            'designation' => '2',
            'storeImage' => portolisar.celestial_object.store_image.url,
            'storeImageMedium' => portolisar.celestial_object.store_image.medium.url,
            'storeImageSmall' => portolisar.celestial_object.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil,
            'locationLabel' => portolisar.celestial_object.location_label,
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => portolisar.starsystem.store_image.url,
              'storeImageMedium' => portolisar.starsystem.store_image.medium.url,
              'storeImageSmall' => portolisar.starsystem.store_image.small.url,
              'mapX' => nil,
              'mapY' => nil,
              'description' => nil,
              'type' => nil,
              'size' => nil,
              'population' => nil,
              'economy' => nil,
              'danger' => nil,
              'status' => nil,
              'locationLabel' => portolisar.starsystem.location_label,
            },
          },
          'createdAt' => portolisar.created_at.utc.iso8601,
          'updatedAt' => portolisar.updated_at.utc.iso8601
        }]
      end
      let(:show_result) do
        {
          'name' => 'Port Olisar',
          'slug' => 'port-olisar',
          'location' => nil,
          'locationLabel' => portolisar.location_label,
          'type' => 'hub',
          'typeLabel' => 'Hub',
          'storeImage' => portolisar.store_image.url,
          'storeImageMedium' => portolisar.store_image.medium.url,
          'storeImageSmall' => portolisar.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
          'hasImages' => false,
          'shopListLabel' => portolisar.shop_list_label,
          'habitationCounts' => [{
            'count' => 1,
            'type' => 'container',
            'typeLabel' => 'Container'
          }],
          'dockCounts' => [{
            'size' => 'Medium',
            'count' => 1,
            'type' => 'dockingport',
            'typeLabel' => 'Dockingport'
          }, {
            'size' => 'Large',
            'count' => 2,
            'type' => 'landingpad',
            'typeLabel' => 'Landingpad'
          }],
          'celestialObject' => {
            'name' => 'Crusader',
            'slug' => 'crusader',
            'type' => nil,
            'designation' => '2',
            'storeImage' => portolisar.celestial_object.store_image.url,
            'storeImageMedium' => portolisar.celestial_object.store_image.medium.url,
            'storeImageSmall' => portolisar.celestial_object.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil,
            'locationLabel' => portolisar.celestial_object.location_label,
            'starsystem' => {
              'name' => 'Stanton',
              'slug' => 'stanton',
              'storeImage' => portolisar.starsystem.store_image.url,
              'storeImageMedium' => portolisar.starsystem.store_image.medium.url,
              'storeImageSmall' => portolisar.starsystem.store_image.small.url,
              'mapX' => nil,
              'mapY' => nil,
              'description' => nil,
              'type' => nil,
              'size' => nil,
              'population' => nil,
              'economy' => nil,
              'danger' => nil,
              'status' => nil,
              'locationLabel' => portolisar.starsystem.location_label,
            },
          },
          'starsystem' => {
            'name' => 'Stanton',
            'slug' => 'stanton',
            'storeImage' => portolisar.starsystem.store_image.url,
            'storeImageMedium' => portolisar.starsystem.store_image.medium.url,
            'storeImageSmall' => portolisar.starsystem.store_image.small.url,
            'mapX' => nil,
            'mapY' => nil,
            'description' => nil,
            'type' => nil,
            'size' => nil,
            'population' => nil,
            'economy' => nil,
            'danger' => nil,
            'status' => nil,
            'locationLabel' => portolisar.starsystem.location_label,
          },
          'shops' => [{
            'name' => 'Admin Office',
            'slug' => 'admin-office',
            'type' => 'admin',
            'typeLabel' => 'Admin Office',
            'locationLabel' => portolisar.shops.first.location_label,
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar.shops.first.store_image.url,
            'storeImageMedium' => portolisar.shops.first.store_image.medium.url,
            'storeImageSmall' => portolisar.shops.first.store_image.small.url,
            'station' => {
              'name' => portolisar.name,
              'slug' => portolisar.slug,
            },
          }, {
            'name' => 'Dumpers Depot',
            'slug' => 'dumpers-depot',
            'type' => 'components',
            'typeLabel' => 'Components Store',
            'locationLabel' => portolisar.shops.first.location_label,
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar.shops.first.store_image.url,
            'storeImageMedium' => portolisar.shops.first.store_image.medium.url,
            'storeImageSmall' => portolisar.shops.first.store_image.small.url,
            'station' => {
              'name' => portolisar.name,
              'slug' => portolisar.slug,
            },
          }, {
            'name' => 'New Deal',
            'slug' => 'new-deal',
            'type' => 'ships',
            'typeLabel' => 'Ship Store',
            'locationLabel' => portolisar.shops.last.location_label,
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar.shops.last.store_image.url,
            'storeImageMedium' => portolisar.shops.last.store_image.medium.url,
            'storeImageSmall' => portolisar.shops.last.store_image.small.url,
            'station' => {
              'name' => portolisar.name,
              'slug' => portolisar.slug,
            },
          }],
          'docks' => [{
            'name' => 'Dockingport 01',
            'group' => nil,
            'size' => 'medium',
            'sizeLabel' => 'Medium',
            'type' => 'dockingport',
            'typeLabel' => 'Dockingport'
          }, {
            'name' => 'Landingpad 01',
            'group' => nil,
            'size' => 'large',
            'sizeLabel' => 'Large',
            'type' => 'landingpad',
            'typeLabel' => 'Landingpad'
          }, {
            'name' => 'Landingpad 02',
            'group' => nil,
            'size' => 'large',
            'sizeLabel' => 'Large',
            'type' => 'landingpad',
            'typeLabel' => 'Landingpad'
          }],
          'habitations' => [{
            'name' => 'Hab 1',
            'habitationName' => nil,
            'type' => 'container',
            'typeLabel' => 'Container'
          }],
          'images' => [],
          'createdAt' => portolisar.created_at.utc.iso8601,
          'updatedAt' => portolisar.updated_at.utc.iso8601
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
          get :show, params: { slug: portolisar.slug }

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
          get :show, params: { slug: portolisar.slug }

          assert_response :ok
          json = JSON.parse response.body

          assert_equal show_result, json
        end
      end
    end
  end
end
