# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    module Rsi
      class OrgsControllerTest < ActionController::TestCase
        setup do
          @request.headers['Accept'] = Mime[:json]
          @request.headers['Content-Type'] = Mime[:json].to_s
        end

        tests Api::V1::Rsi::OrgsController

        it 'should render 200 for show' do
          VCR.use_cassette('rsi_org_loader_org') do
            get :show, params: { sid: 'oppf' }

            assert_response :ok
            json = JSON.parse response.body

            expected = {
              'name' => 'Operation Pitchfork',
              'sid' => 'oppf',
              'archetype' => 'Organization',
              'mainActivity' => 'Scouting',
              'secondaryActivity' => 'Security',
              'recruiting' => true,
              'commitment' => 'Casual',
              'memberCount' => 5262,
              'rpg' => false,
              'exclusive' => false,
              'logo' => 'https://robertsspaceindustries.com/media/91scp32ik2k2ur/logo/OPPF-Logo.png'
            }

            assert_equal expected, json
          end
        end
      end
    end
  end
end
