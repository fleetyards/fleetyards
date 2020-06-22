# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class FleetsControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::FleetsController

      let(:starfleet) { fleets :starfleet }

      describe 'without session' do
        it 'should render 403 for vehicles' do
          get :vehicles, params: { slug: starfleet.slug }

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        it 'should render 403 for quick-stats' do
          get :quick_stats, params: { slug: starfleet.slug }

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        it 'should render 403 for fleetchart' do
          get :fleetchart, params: { slug: starfleet.slug }

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end
      end

      describe 'with session' do
        let(:data) { users :data }

        before do
          sign_in data
        end

        describe '#vehicles' do
          it 'should return list for index' do
            get :vehicles, params: { slug: starfleet.slug }

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item['model']['name'] }

            assert_equal(%w[600i Andromeda], data)
          end

          it 'should return list with loaners for index' do
            get :vehicles, params: { slug: starfleet.slug, q: { loanerEq: true } }

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item['model']['name'] }

            assert_equal(%w[600i Andromeda PTV], data)
          end

          it 'should return list with only loaners for index' do
            get :vehicles, params: { slug: starfleet.slug, q: { loanerEq: 'only' } }

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item['model']['name'] }

            assert_equal(%w[PTV], data)
          end
        end

        describe '#vehicles grouped' do
          it 'should return list for index' do
            get :vehicles, params: { slug: starfleet.slug, grouped: true }

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item['name'] }

            assert_equal(%w[600i Andromeda], data)
          end

          it 'should return list with loaners for index' do
            get :vehicles, params: { slug: starfleet.slug, grouped: true, q: { loanerEq: true } }

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item['name'] }

            assert_equal(%w[600i Andromeda PTV], data)
          end

          it 'should return list with only loaners for index' do
            get :vehicles, params: { slug: starfleet.slug, grouped: true, q: { loanerEq: 'only' } }

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item['name'] }

            assert_equal(%w[PTV], data)
          end
        end

        describe '#fleetchart' do
          it 'should return list for index' do
            get :fleetchart, params: { slug: starfleet.slug }

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item['model']['name'] }

            assert_equal(%w[Andromeda 600i], data)
          end

          it 'should return list with loaners for index' do
            get :fleetchart, params: { slug: starfleet.slug, q: { loanerEq: true } }

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item['model']['name'] }

            assert_equal(%w[Andromeda 600i PTV], data)
          end

          it 'should return list with only loaners for index' do
            get :fleetchart, params: { slug: starfleet.slug, q: { loanerEq: 'only' } }

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item['model']['name'] }

            assert_equal(%w[PTV], data)
          end
        end
      end
    end
  end
end
