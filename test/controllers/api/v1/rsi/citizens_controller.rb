# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    module Rsi
      class CitizensControllerTest < ActionController::TestCase
        setup do
          @request.headers['Accept'] = Mime[:json]
          @request.headers['Content-Type'] = Mime[:json].to_s
        end

        tests Api::V1::Rsi::CitizensController

        it 'should render 200 for show' do
          VCR.use_cassette('rsi_org_loader_citizen') do
            get :show, params: { handle: 'torlekmaru' }

            assert_response :ok
            json = JSON.parse response.body

            expected = {
              'username' => 'Torlek Maru',
              'handle' => 'torlekmaru',
              'avatar' => "#{Rails.application.secrets[:rsi_endpoint]}/media/t7fv6wn954w41r/heap_infobox/Screenshot-2017-09-27-094353.png",
              'title' => 'Guardian Angel',
              'enlisted' => 'Nov 22, 2012',
              'citizenRecord' => '#79955',
              'location' => 'Germany , Schleswig-Holstein',
              'languages' => 'English, German',
              'orgs' => %w[MERCCORP AVOCADO]
            }

            assert_equal expected, json
          end
        end
      end
    end
  end
end
