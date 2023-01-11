# frozen_string_literal: true

require 'test_helper'
require 'open_api_test_helper'

module Api
  module V2
    class AuthTokensControllerTest < ActionDispatch::IntegrationTest
      include OpenApiTestHelper

      let(:auth_token) { auth_tokens :test_token }

      describe 'without session' do
        describe 'GET /api/v2/users/auth-tokens' do
          it 'conforms to response schema with 401 response code' do
            get '/api/v2/users/auth-tokens', as: :json

            assert_response_schema_confirm(401)
          end
        end

        describe 'POST /api/v2/users/auth-tokens' do
          it 'conforms to response schema with 401 response code' do
            post '/api/v2/users/auth-tokens', as: :json

            assert_response_schema_confirm(401)
          end
        end

        describe 'DELETE /api/v2/users/auth-tokens/{id}' do
          it 'conforms to response schema with 401 response code' do
            delete "/api/v2/users/auth-tokens/#{auth_token.id}", as: :json

            assert_response_schema_confirm(401)
          end
        end
      end

      describe 'with session' do
        let(:data) { users :data }

        before do
          sign_in data
        end

        describe 'GET /api/v2/users/auth-tokens' do
          it 'conforms to response schema with 200 response code' do
            get '/api/v2/users/auth-tokens', as: :json

            assert_response_schema_confirm(200)
          end
        end

        describe 'POST /api/v2/users/auth-tokens' do
          it 'conforms to request schema ' do
            post '/api/v2/users/auth-tokens', as: :json, params: {
              description: 'Test Token'
            }

            assert_request_schema_confirm
          end

          it 'conforms to response schema with 201 response code' do
            post '/api/v2/users/auth-tokens', as: :json, params: {
              description: 'Test Token',
              expiredAt: '2023-12-01'
            }

            assert_response_schema_confirm(201)
          end

          it 'conforms to response schema with 400 response code' do
            post '/api/v2/users/auth-tokens', as: :json

            assert_response_schema_confirm(400)
          end
        end

        describe 'DELETE /api/v2/users/auth-tokens/{id}' do
          it 'conforms to response schema with 200 response code' do
            delete "/api/v2/users/auth-tokens/#{auth_token.id}", as: :json

            assert_response_schema_confirm(200)
          end
        end
      end
    end
  end
end
