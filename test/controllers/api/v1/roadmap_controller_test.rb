# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class RoadmapControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::RoadmapController

      let(:first_roadmap_item) { roadmap_items :one }
      let(:second_roadmap_item) { roadmap_items :two }
      let(:index_result) do
        [{
          'id' => second_roadmap_item.id,
          'name' => 'MyString',
          'release' => '4.0',
          'releaseDescription' => nil,
          'rsiReleaseId' => 1,
          'description' => 'MyText',
          'body' => 'MyText',
          'rsiCategoryId' => 1,
          'image' => 'MyString',
          'storeImage' => second_roadmap_item.store_image.url,
          'storeImageMedium' => second_roadmap_item.store_image.medium.url,
          'storeImageSmall' => second_roadmap_item.store_image.small.url,
          'released' => false,
          'tasks' => 1,
          'completed' => 1,
          'model' => nil,
          'lastVersionChangedAt' => second_roadmap_item.last_version_changed_at.iso8601,
          'lastVersionChangedAtLabel' => I18n.l(second_roadmap_item.last_version_changed_at.utc, format: :label),
          'lastVersion' => nil,
          'createdAt' => second_roadmap_item.created_at.utc.iso8601,
          'updatedAt' => second_roadmap_item.updated_at.utc.iso8601
        }, {
          'id' => first_roadmap_item.id,
          'name' => 'MyString',
          'release' => '4.1',
          'releaseDescription' => nil,
          'rsiReleaseId' => 1,
          'description' => 'MyText',
          'body' => 'MyText',
          'rsiCategoryId' => 1,
          'image' => 'MyString',
          'storeImage' => first_roadmap_item.store_image.url,
          'storeImageMedium' => first_roadmap_item.store_image.medium.url,
          'storeImageSmall' => first_roadmap_item.store_image.small.url,
          'released' => false,
          'tasks' => 1,
          'completed' => 1,
          'model' => nil,
          'lastVersionChangedAt' => first_roadmap_item.last_version_changed_at.iso8601,
          'lastVersionChangedAtLabel' => I18n.l(first_roadmap_item.last_version_changed_at.utc, format: :label),
          'lastVersion' => nil,
          'createdAt' => first_roadmap_item.created_at.utc.iso8601,
          'updatedAt' => first_roadmap_item.updated_at.utc.iso8601
        }]
      end

      describe 'without session' do
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
