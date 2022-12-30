# frozen_string_literal: true

require 'test_helper'
require 'open_api_test_helper'

module Api
  module V2
    class AuthTokensControllerTest < ActionDispatch::IntegrationTest
      include OpenApiTestHelper

      describe 'GET /api/v2/users/auth-tokens' do
        describe 'without session' do
          it 'conforms to schema with 401 response code' do
            get '/api/v2/users/auth-tokens', as: :json

            assert_response_schema_confirm(401)
          end
        end

        describe 'with session' do
          let(:data) { users :data }

          before do
            sign_in data
          end

          it 'conforms to schema with 200 response code' do
            get '/api/v2/users/auth-tokens', as: :json

            assert_response_schema_confirm(200)
          end
        end
      end
    end
  end
end
