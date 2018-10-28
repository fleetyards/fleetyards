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
          'station' => {
            'name' => 'Port Olisar',
            'slug' => 'port-olisar'
          },
          'celestialObject' => {
            'name' => 'Crusader',
            'slug' => 'crusader'
          },
          'createdAt' => new_deal.created_at.to_time.iso8601,
          'updatedAt' => new_deal.updated_at.to_time.iso8601
        }
      end

      describe 'without session' do
        it 'should return a single record for show' do
          get :show, params: { station_slug: new_deal.station.slug, slug: new_deal.slug }

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

        it 'should return a single record for show' do
          get :show, params: { station_slug: new_deal.station.slug, slug: new_deal.slug }

          assert_response :ok
          json = JSON.parse response.body

          expected = show_result

          assert_equal expected, json
        end
      end
    end
  end
end
