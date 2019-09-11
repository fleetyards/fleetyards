# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ShopsControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::ShopsController

      let(:new_deal) { shops :new_deal }
      let(:dumpers) { shops :dumpers }
      let(:admin_olisar) { shops :admin_olisar }
      let(:admin_daymar) { shops :admin_daymar }
      let(:admin_yela) { shops :admin_yela }
      let(:show_result) do
        {
          'name' => 'New Deal',
          'slug' => 'new-deal',
          'type' => 'ships',
          'typeLabel' => 'Ship Store',
          'rental' => false,
          'buying' => false,
          'selling' => false,
          'storeImage' => new_deal.store_image.url,
          'storeImageMedium' => new_deal.store_image.medium.url,
          'storeImageSmall' => new_deal.store_image.small.url,
          'station' => {
            'name' => 'Port Olisar',
            'slug' => 'port-olisar'
          },
          'celestialObject' => {
            'name' => 'Crusader',
            'slug' => 'crusader'
          },
          'createdAt' => new_deal.created_at.iso8601,
          'updatedAt' => new_deal.updated_at.iso8601
        }
      end
      let(:index_result) do
        [{
          'name' => 'Admin Office',
          'slug' => 'admin-office',
          'type' => 'admin',
          'typeLabel' => 'Admin Office',
          'rental' => false,
          'buying' => false,
          'selling' => false,
          'storeImage' => admin_daymar.store_image.url,
          'storeImageMedium' => admin_daymar.store_image.medium.url,
          'storeImageSmall' => admin_daymar.store_image.small.url,
          'station' => {
            'name' => 'ArcCorp',
            'slug' => 'arccorp'
          },
          'celestialObject' => {
            'name' => 'Daymar',
            'slug' => 'daymar'
          },
          'createdAt' => admin_daymar.created_at.iso8601,
          'updatedAt' => admin_daymar.updated_at.iso8601
        }, {
          'name' => 'Admin Office',
          'slug' => 'admin-office',
          'type' => 'admin',
          'typeLabel' => 'Admin Office',
          'rental' => false,
          'buying' => false,
          'selling' => false,
          'storeImage' => admin_yela.store_image.url,
          'storeImageMedium' => admin_yela.store_image.medium.url,
          'storeImageSmall' => admin_yela.store_image.small.url,
          'station' => {
            'name' => 'ArcCorp',
            'slug' => 'arccorp'
          },
          'celestialObject' => {
            'name' => 'Yela',
            'slug' => 'yela'
          },
          'createdAt' => admin_yela.created_at.iso8601,
          'updatedAt' => admin_yela.updated_at.iso8601
        }, {
          'name' => 'Admin Office',
          'slug' => 'admin-office',
          'type' => 'admin',
          'typeLabel' => 'Admin Office',
          'rental' => false,
          'buying' => false,
          'selling' => false,
          'storeImage' => admin_olisar.store_image.url,
          'storeImageMedium' => admin_olisar.store_image.medium.url,
          'storeImageSmall' => admin_olisar.store_image.small.url,
          'station' => {
            'name' => 'Port Olisar',
            'slug' => 'port-olisar'
          },
          'celestialObject' => {
            'name' => 'Crusader',
            'slug' => 'crusader'
          },
          'createdAt' => admin_olisar.created_at.iso8601,
          'updatedAt' => admin_olisar.updated_at.iso8601
        }, {
          'name' => 'Dumpers Depot',
          'slug' => 'dumpers-depot',
          'type' => 'components',
          'typeLabel' => 'Components Store',
          'rental' => false,
          'buying' => false,
          'selling' => false,
          'storeImage' => dumpers.store_image.url,
          'storeImageMedium' => dumpers.store_image.medium.url,
          'storeImageSmall' => dumpers.store_image.small.url,
          'station' => {
            'name' => 'Port Olisar',
            'slug' => 'port-olisar'
          },
          'celestialObject' => {
            'name' => 'Crusader',
            'slug' => 'crusader'
          },
          'createdAt' => dumpers.created_at.iso8601,
          'updatedAt' => dumpers.updated_at.iso8601
        }, {
          'name' => 'New Deal',
          'slug' => 'new-deal',
          'type' => 'ships',
          'typeLabel' => 'Ship Store',
          'rental' => false,
          'buying' => false,
          'selling' => false,
          'storeImage' => new_deal.store_image.url,
          'storeImageMedium' => new_deal.store_image.medium.url,
          'storeImageSmall' => new_deal.store_image.small.url,
          'station' => {
            'name' => 'Port Olisar',
            'slug' => 'port-olisar'
          },
          'celestialObject' => {
            'name' => 'Crusader',
            'slug' => 'crusader'
          },
          'createdAt' => new_deal.created_at.iso8601,
          'updatedAt' => new_deal.updated_at.iso8601
        }]
      end

      describe 'without session' do
        it 'should return a single record for show' do
          get :show, params: { station_slug: new_deal.station.slug, slug: new_deal.slug }

          assert_response :ok
          json = JSON.parse response.body

          assert_equal show_result, json
        end

        it 'should return list for index' do
          get :index

          assert_response :ok
          json = JSON.parse response.body

          assert_equal index_result, json
        end
      end

      describe 'with session' do
        let(:data) { users :data }

        before do
          sign_in data
        end

        it 'should return a single record for show' do
          get :show, params: { station_slug: new_deal.station.slug, slug: new_deal.slug }

          assert_response :ok
          json = JSON.parse response.body

          assert_equal show_result, json
        end

        it 'should return list for index' do
          get :index

          assert_response :ok
          json = JSON.parse response.body

          assert_equal index_result, json
        end
      end
    end
  end
end
