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
      let(:arccorp_daymar) { stations :arccorp_daymar }
      let(:arccorp_yela) { stations :arccorp_yela }
      let(:index_result) do
        [{
          'name' => 'ArcCorp',
          'slug' => 'arccorp',
          'location' => nil,
          'locationLabel' => 'on Yela',
          'type' => 'outpost',
          'typeLabel' => 'Outpost',
          'storeImage' => arccorp_yela.store_image.url,
          'storeImageMedium' => arccorp_yela.store_image.medium.url,
          'storeImageSmall' => arccorp_yela.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
          'celestialObject' => {
            'name' => arccorp_yela.celestial_object.name,
            'slug' => arccorp_yela.celestial_object.slug,
            'type' => nil,
            'designation' => arccorp_yela.celestial_object.designation,
            'storeImage' => arccorp_yela.celestial_object.store_image.url,
            'storeImageMedium' => arccorp_yela.celestial_object.store_image.medium.url,
            'storeImageSmall' => arccorp_yela.celestial_object.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil
          },
          'starsystem' => {
            'name' => 'Stanton',
            'slug' => 'stanton',
            'storeImage' => arccorp_yela.starsystem.store_image.url,
            'storeImageMedium' => arccorp_yela.starsystem.store_image.medium.url,
            'storeImageSmall' => arccorp_yela.starsystem.store_image.small.url,
            'mapX' => nil,
            'mapY' => nil,
            'description' => nil,
            'type' => nil,
            'size' => nil,
            'population' => nil,
            'economy' => nil,
            'danger' => nil,
            'status' => nil
          },
          'shops' => [{
            'name' => 'Admin Office',
            'slug' => 'admin-office',
            'type' => 'admin',
            'typeLabel' => 'Admin Office',
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => arccorp_yela.shops.first.store_image.url,
            'storeImageMedium' => arccorp_yela.shops.first.store_image.medium.url,
            'storeImageSmall' => arccorp_yela.shops.first.store_image.small.url
          }],
          'dockCounts' => [],
          'docks' => [],
          'habitationCounts' => [],
          'habitations' => [],
          'hasImages' => false,
          'createdAt' => arccorp_yela.created_at.utc.iso8601,
          'updatedAt' => arccorp_yela.updated_at.utc.iso8601
        }, {
          'name' => 'ArcCorp',
          'slug' => 'arccorp',
          'location' => nil,
          'locationLabel' => 'on Daymar',
          'type' => 'outpost',
          'typeLabel' => 'Outpost',
          'storeImage' => arccorp_daymar.store_image.url,
          'storeImageMedium' => arccorp_daymar.store_image.medium.url,
          'storeImageSmall' => arccorp_daymar.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
          'celestialObject' => {
            'name' => arccorp_daymar.celestial_object.name,
            'slug' => arccorp_daymar.celestial_object.slug,
            'type' => nil,
            'designation' => arccorp_daymar.celestial_object.designation,
            'storeImage' => arccorp_daymar.celestial_object.store_image.url,
            'storeImageMedium' => arccorp_daymar.celestial_object.store_image.medium.url,
            'storeImageSmall' => arccorp_daymar.celestial_object.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil
          },
          'starsystem' => {
            'name' => 'Stanton',
            'slug' => 'stanton',
            'storeImage' => arccorp_daymar.starsystem.store_image.url,
            'storeImageMedium' => arccorp_daymar.starsystem.store_image.medium.url,
            'storeImageSmall' => arccorp_daymar.starsystem.store_image.small.url,
            'mapX' => nil,
            'mapY' => nil,
            'description' => nil,
            'type' => nil,
            'size' => nil,
            'population' => nil,
            'economy' => nil,
            'danger' => nil,
            'status' => nil
          },
          'shops' => [{
            'name' => 'Admin Office',
            'slug' => 'admin-office',
            'type' => 'admin',
            'typeLabel' => 'Admin Office',
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => arccorp_daymar.shops.first.store_image.url,
            'storeImageMedium' => arccorp_daymar.shops.first.store_image.medium.url,
            'storeImageSmall' => arccorp_daymar.shops.first.store_image.small.url
          }],
          'dockCounts' => [],
          'docks' => [],
          'habitationCounts' => [],
          'habitations' => [],
          'hasImages' => false,
          'createdAt' => arccorp_daymar.created_at.utc.iso8601,
          'updatedAt' => arccorp_daymar.updated_at.utc.iso8601
        }, {
          'name' => 'Corvolex Shipping Hub',
          'slug' => 'corvolex',
          'location' => nil,
          'locationLabel' => 'in orbit around Daymar',
          'type' => 'cargo-station',
          'typeLabel' => 'Cargo Station',
          'storeImage' => corvolex.store_image.url,
          'storeImageMedium' => corvolex.store_image.medium.url,
          'storeImageSmall' => corvolex.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
          'celestialObject' => {
            'name' => 'Daymar',
            'slug' => 'daymar',
            'type' => nil,
            'designation' => '4',
            'storeImage' => corvolex.celestial_object.store_image.url,
            'storeImageMedium' => corvolex.celestial_object.store_image.medium.url,
            'storeImageSmall' => corvolex.celestial_object.store_image.small.url,
            'description' => nil,
            'habitable' => nil,
            'fairchanceact' => nil,
            'subType' => nil,
            'size' => nil,
            'danger' => nil,
            'economy' => nil,
            'population' => nil
          },
          'starsystem' => {
            'name' => 'Stanton',
            'slug' => 'stanton',
            'storeImage' => corvolex.starsystem.store_image.url,
            'storeImageMedium' => corvolex.starsystem.store_image.medium.url,
            'storeImageSmall' => corvolex.starsystem.store_image.small.url,
            'mapX' => nil,
            'mapY' => nil,
            'description' => nil,
            'type' => nil,
            'size' => nil,
            'population' => nil,
            'economy' => nil,
            'danger' => nil,
            'status' => nil
          },
          'shops' => [],
          'dockCounts' => [{
            'size' => 'Small',
            'count' => 1,
            'type' => 'dockingport',
            'typeLabel' => 'Dockingport'
          }],
          'docks' => [{
            'name' => 'Dockingport 01',
            'group' => nil,
            'size' => 'small',
            'sizeLabel' => 'Small',
            'type' => 'dockingport',
            'typeLabel' => 'Dockingport'
          }],
          'habitationCounts' => [],
          'habitations' => [],
          'hasImages' => false,
          'createdAt' => corvolex.created_at.utc.iso8601,
          'updatedAt' => corvolex.updated_at.utc.iso8601
        }, {
          'name' => 'Port Olisar',
          'slug' => 'port-olisar',
          'location' => nil,
          'locationLabel' => 'in orbit around Crusader',
          'type' => 'hub',
          'typeLabel' => 'Hub',
          'storeImage' => portolisar.store_image.url,
          'storeImageMedium' => portolisar.store_image.medium.url,
          'storeImageSmall' => portolisar.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
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
            'population' => nil
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
            'status' => nil
          },
          'shops' => [{
            'name' => 'Admin Office',
            'slug' => 'admin-office',
            'type' => 'admin',
            'typeLabel' => 'Admin Office',
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar.shops.first.store_image.url,
            'storeImageMedium' => portolisar.shops.first.store_image.medium.url,
            'storeImageSmall' => portolisar.shops.first.store_image.small.url
          }, {
            'name' => 'Dumpers Depot',
            'slug' => 'dumpers-depot',
            'type' => 'components',
            'typeLabel' => 'Components Store',
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar.shops.second.store_image.url,
            'storeImageMedium' => portolisar.shops.second.store_image.medium.url,
            'storeImageSmall' => portolisar.shops.second.store_image.small.url
          }, {
            'name' => 'New Deal',
            'slug' => 'new-deal',
            'type' => 'ships',
            'typeLabel' => 'Ship Store',
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar.shops.last.store_image.url,
            'storeImageMedium' => portolisar.shops.last.store_image.medium.url,
            'storeImageSmall' => portolisar.shops.last.store_image.small.url
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
          'habitationCounts' => [{
            'count' => 1,
            'type' => 'container',
            'typeLabel' => 'Container'
          }],
          'habitations' => [{
            'name' => 'Hab 1',
            'habitationName' => nil,
            'type' => 'container',
            'typeLabel' => 'Container'
          }],
          'hasImages' => false,
          'createdAt' => portolisar.created_at.utc.iso8601,
          'updatedAt' => portolisar.updated_at.utc.iso8601
        }]
      end
      let(:show_result) do
        {
          'name' => 'Port Olisar',
          'slug' => 'port-olisar',
          'location' => nil,
          'locationLabel' => 'in orbit around Crusader',
          'type' => 'hub',
          'typeLabel' => 'Hub',
          'storeImage' => portolisar.store_image.url,
          'storeImageMedium' => portolisar.store_image.medium.url,
          'storeImageSmall' => portolisar.store_image.small.url,
          'description' => nil,
          'backgroundImage' => nil,
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
            'population' => nil
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
            'status' => nil
          },
          'shops' => [{
            'name' => 'Admin Office',
            'slug' => 'admin-office',
            'type' => 'admin',
            'typeLabel' => 'Admin Office',
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar.shops.first.store_image.url,
            'storeImageMedium' => portolisar.shops.first.store_image.medium.url,
            'storeImageSmall' => portolisar.shops.first.store_image.small.url
          }, {
            'name' => 'Dumpers Depot',
            'slug' => 'dumpers-depot',
            'type' => 'components',
            'typeLabel' => 'Components Store',
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar.shops.first.store_image.url,
            'storeImageMedium' => portolisar.shops.first.store_image.medium.url,
            'storeImageSmall' => portolisar.shops.first.store_image.small.url
          }, {
            'name' => 'New Deal',
            'slug' => 'new-deal',
            'type' => 'ships',
            'typeLabel' => 'Ship Store',
            'rental' => false,
            'buying' => false,
            'selling' => false,
            'storeImage' => portolisar.shops.last.store_image.url,
            'storeImageMedium' => portolisar.shops.last.store_image.medium.url,
            'storeImageSmall' => portolisar.shops.last.store_image.small.url
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
          'habitationCounts' => [{
            'count' => 1,
            'type' => 'container',
            'typeLabel' => 'Container'
          }],
          'habitations' => [{
            'name' => 'Hab 1',
            'habitationName' => nil,
            'type' => 'container',
            'typeLabel' => 'Container'
          }],
          'hasImages' => false,
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
