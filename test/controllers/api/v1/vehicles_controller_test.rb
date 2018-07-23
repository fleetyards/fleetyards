# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class VehiclesControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::VehiclesController

      describe "without session" do
        it "should render 403 for index" do
          get :index

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal "unauthorized", json["code"]
        end

        it "should render 403 for count" do
          get :count

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal "unauthorized", json["code"]
        end
      end

      describe "with session" do
        let(:data) { users :data }

        before do
          sign_in data
        end

        it "should return list for index" do
          get :index

          assert_response :ok
          json = JSON.parse response.body

          expected = [{
            'id' => data.vehicles.first.id,
            'name' => 'Enterprise',
            'purchased' => true,
            'flagship' => false,
            'nameVisible' => false,
            'saleNotify' => false,
            'model' => {
              'id' => data.vehicles.first.model.id,
              'name' => 'Andromeda',
              'rsiName' => nil,
              'slug' => 'andromeda',
              'rsiSlug' => nil,
              'description' => nil,
              'length' => 61.2,
              'beam' => 10.2,
              'height' => 10.2,
              'mass' => 1000.02,
              'cargo' => '10.0',
              'minCrew' => 1,
              'maxCrew' => 3,
              'scmSpeed' => nil,
              'afterburnerSpeed' => nil,
              'groundSpeed' => nil,
              'afterburnerGroundSpeed' => nil,
              'pitchMax' => nil,
              'yawMax' => nil,
              'rollMax' => nil,
              'xaxisAcceleration' => nil,
              'yaxisAcceleration' => nil,
              'zaxisAcceleration' => nil,
              'size' => nil,
              'storeImage' => data.vehicles.first.model.store_image.url,
              'fleetchartImage' => nil,
              'brochure' => nil,
              'storeUrl' => 'https://robertsspaceindustries.com',
              'price' => nil,
              'lastPrice' => nil,
              'onSale' => false,
              'productionStatus' => nil,
              'productionNote' => nil,
              'classification' => 'multi_role',
              'classificationLabel' => 'Multi role',
              'focus' => nil,
              'rsiId' => nil,
              'manufacturer' => {
                'name' => 'RSI',
                'slug' => 'rsi'
              },
              'createdAt' => data.vehicles.first.model.created_at.to_time.iso8601,
              'updatedAt' => data.vehicles.first.model.updated_at.to_time.iso8601
            },
            'hangarGroupIds' => [],
            'createdAt' => data.vehicles.first.created_at.to_time.iso8601,
            'updatedAt' => data.vehicles.first.updated_at.to_time.iso8601
          }]
          assert_equal expected, json
        end

        it "should return counts for count" do
          get :count

          assert_response :ok
          json = JSON.parse response.body

          expected = {
            'total' => 1,
            'classifications' => [{
              'name' => 'multi_role',
              'label' => 'Multi role',
              'count' => 1
            }]
          }
          assert_equal expected, json
        end

        it "should return counts for count" do
          get :count, params: { q: '{ "model_classification_in": ["combat"] }' }

          assert_response :ok
          json = JSON.parse response.body

          expected = {
            'total' => 0,
            'classifications' => []
          }
          assert_equal expected, json
        end
      end
    end
  end
end
