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
      let(:portolisar_admin) { portolisar.shops.visible.order(:name).first }
      let(:portolisar_dumpers) { portolisar.shops.visible.order(:name).second }
      let(:portolisar_new_deal) { portolisar.shops.visible.order(:name).last }
      let(:corvolex) { stations :corvolex }
      let(:arccorp_daymar) { stations :arccorp_daymar }
      let(:arccorp_yela) { stations :arccorp_yela }
      let(:index_result) do
        [{
          'name' => 'ArcCorp 001',
          'slug' => 'arccorp',
          'location' => nil,
          'locationLabel' => arccorp_daymar.location_label,
          'type' => 'outpost',
          'typeLabel' => 'Outpost',
          'classification' => nil,
          'classificationLabel' => nil,
          'habitable' => true,
          'storeImage' => arccorp_daymar.store_image.url,
          'storeImageLarge' => arccorp_daymar.store_image.large.url,
          'storeImageMedium' => arccorp_daymar.store_image.medium.url,
          'storeImageSmall' => arccorp_daymar.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
          'hasImages' => false,
          'shopListLabel' => arccorp_daymar.shop_list_label,
          'refinery' => nil,
          'cargoHub' => nil,
          'habitationCounts' => [],
          'dockCounts' => [],
          'celestialObject' => {
            'name' => 'Daymar',
            'slug' => 'daymar',
            'type' => nil,
            'designation' => '4',
            'storeImage' => daymar.store_image.url,
            'storeImageLarge' => daymar.store_image.large.url,
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
              'storeImageLarge' => crusader.store_image.large.url,
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
                'storeImageLarge' => crusader.starsystem.store_image.large.url,
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
              'storeImageLarge' => crusader.starsystem.store_image.large.url,
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
          'name' => 'ArcCorp 002',
          'slug' => 'arccorp',
          'location' => nil,
          'locationLabel' => arccorp_yela.location_label,
          'type' => 'outpost',
          'typeLabel' => 'Outpost',
          'classification' => nil,
          'classificationLabel' => nil,
          'habitable' => true,
          'storeImage' => arccorp_yela.store_image.url,
          'storeImageLarge' => arccorp_yela.store_image.large.url,
          'storeImageMedium' => arccorp_yela.store_image.medium.url,
          'storeImageSmall' => arccorp_yela.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
          'hasImages' => false,
          'shopListLabel' => arccorp_yela.shop_list_label,
          'refinery' => nil,
          'cargoHub' => nil,
          'habitationCounts' => [],
          'dockCounts' => [],
          'celestialObject' => {
            'name' => 'Yela',
            'slug' => 'yela',
            'type' => nil,
            'designation' => '3',
            'storeImage' => yela.store_image.url,
            'storeImageLarge' => yela.store_image.large.url,
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
              'storeImageLarge' => crusader.store_image.large.url,
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
                'storeImageLarge' => crusader.starsystem.store_image.large.url,
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
              'storeImageLarge' => crusader.starsystem.store_image.large.url,
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
          'createdAt' => arccorp_yela.created_at.utc.iso8601,
          'updatedAt' => arccorp_yela.updated_at.utc.iso8601
        }, {
          'name' => 'Corvolex Shipping Hub',
          'slug' => 'corvolex',
          'location' => nil,
          'locationLabel' => corvolex.location_label,
          'type' => 'station',
          'typeLabel' => 'Station',
          'classification' => nil,
          'classificationLabel' => nil,
          'habitable' => true,
          'storeImage' => corvolex.store_image.url,
          'storeImageLarge' => corvolex.store_image.large.url,
          'storeImageMedium' => corvolex.store_image.medium.url,
          'storeImageSmall' => corvolex.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
          'hasImages' => false,
          'shopListLabel' => corvolex.shop_list_label,
          'refinery' => nil,
          'cargoHub' => nil,
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
            'storeImageLarge' => daymar.store_image.large.url,
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
              'storeImageLarge' => crusader.store_image.large.url,
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
                'storeImageLarge' => crusader.starsystem.store_image.large.url,
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
              'storeImageLarge' => crusader.starsystem.store_image.large.url,
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
          'type' => 'station',
          'typeLabel' => 'Station',
          'classification' => nil,
          'classificationLabel' => nil,
          'habitable' => true,
          'storeImage' => portolisar.store_image.url,
          'storeImageLarge' => portolisar.store_image.large.url,
          'storeImageMedium' => portolisar.store_image.medium.url,
          'storeImageSmall' => portolisar.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
          'hasImages' => false,
          'shopListLabel' => portolisar.shop_list_label,
          'refinery' => nil,
          'cargoHub' => nil,
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
            'storeImageLarge' => portolisar.celestial_object.store_image.large.url,
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
              'storeImageLarge' => portolisar.starsystem.store_image.large.url,
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
          'type' => 'station',
          'typeLabel' => 'Station',
          'classification' => nil,
          'classificationLabel' => nil,
          'habitable' => true,
          'storeImage' => portolisar.store_image.url,
          'storeImageLarge' => portolisar.store_image.large.url,
          'storeImageMedium' => portolisar.store_image.medium.url,
          'storeImageSmall' => portolisar.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
          'hasImages' => false,
          'shopListLabel' => portolisar.shop_list_label,
          'refinery' => nil,
          'cargoHub' => nil,
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
            'storeImageLarge' => portolisar.celestial_object.store_image.large.url,
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
              'storeImageLarge' => portolisar.starsystem.store_image.large.url,
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
            'storeImageLarge' => portolisar.starsystem.store_image.large.url,
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
            'id' => portolisar_admin.id,
            'name' => 'Admin Office',
            'slug' => 'admin-office',
            'type' => 'admin',
            'typeLabel' => 'Admin Office',
            'stationLabel' => portolisar_admin.station_label,
            'location' => portolisar_admin.location,
            'locationLabel' => portolisar_admin.location_label,
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar_admin.store_image.url,
            'storeImageLarge' => portolisar_admin.store_image.large.url,
            'storeImageMedium' => portolisar_admin.store_image.medium.url,
            'storeImageSmall' => portolisar_admin.store_image.small.url,
            'refineryTerminal' => nil,
            'station' => {
              'name' => portolisar.name,
              'slug' => portolisar.slug,
            },
          }, {
            'id' => portolisar_dumpers.id,
            'name' => 'Dumpers Depot',
            'slug' => 'dumpers-depot',
            'type' => 'components',
            'typeLabel' => 'Components Store',
            'stationLabel' => portolisar_dumpers.station_label,
            'location' => portolisar_dumpers.location,
            'locationLabel' => portolisar_dumpers.location_label,
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar_dumpers.store_image.url,
            'storeImageLarge' => portolisar_dumpers.store_image.large.url,
            'storeImageMedium' => portolisar_dumpers.store_image.medium.url,
            'storeImageSmall' => portolisar_dumpers.store_image.small.url,
            'refineryTerminal' => nil,
            'station' => {
              'name' => portolisar.name,
              'slug' => portolisar.slug,
            },
          }, {
            'id' => portolisar_new_deal.id,
            'name' => 'New Deal',
            'slug' => 'new-deal',
            'type' => 'ships',
            'typeLabel' => 'Ship Store',
            'stationLabel' => portolisar_new_deal.station_label,
            'location' => portolisar_new_deal.location,
            'locationLabel' => portolisar_new_deal.location_label,
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar_new_deal.store_image.url,
            'storeImageLarge' => portolisar_new_deal.store_image.large.url,
            'storeImageMedium' => portolisar_new_deal.store_image.medium.url,
            'storeImageSmall' => portolisar_new_deal.store_image.small.url,
            'refineryTerminal' => nil,
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
