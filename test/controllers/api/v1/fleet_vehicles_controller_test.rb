# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class FleetVehiclesControllerTest < ActionDispatch::IntegrationTest
      let(:starfleet) { fleets :starfleet }

      describe "without session" do
        it "should render 403 for index" do
          get "/api/v1/fleets/#{starfleet.slug}/vehicles", as: :json

          assert_response :unauthorized
          json = JSON.parse response.body

          assert_equal "unauthorized", json["code"]
        end

        it "should render 403 for quick-stats" do
          get "/api/v1/fleets/#{starfleet.slug}/quick-stats", as: :json

          assert_response :unauthorized
          json = JSON.parse response.body

          assert_equal "unauthorized", json["code"]
        end

        it "should render 403 for fleetchart" do
          get "/api/v1/fleets/#{starfleet.slug}/fleetchart", as: :json

          assert_response :unauthorized
          json = JSON.parse response.body

          assert_equal "unauthorized", json["code"]
        end

        it "should render 200 for public" do
          get "/api/v1/fleets/#{starfleet.slug}/public-vehicles", as: :json

          assert_response :ok
        end

        test "should render 200 for public-fleetchart" do
          get "/api/v1/fleets/#{starfleet.slug}/public-fleetchart", as: :json

          assert_response :ok
        end
      end

      describe "with session" do
        let(:data) { users :data }

        before do
          sign_in data
        end

        describe "#index" do
          it "should return list for index" do
            get "/api/v1/fleets/#{starfleet.slug}/vehicles", as: :json

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item["model"]["name"] }

            assert_equal(%w[600i Andromeda], data)
          end

          it "should return list with loaners for index" do
            get "/api/v1/fleets/#{starfleet.slug}/vehicles", params: {q: {loanerEq: true}}, as: :json

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item["model"]["name"] }

            assert_equal(%w[600i Andromeda PTV], data)
          end

          it "should return list with only loaners for index" do
            get "/api/v1/fleets/#{starfleet.slug}/vehicles", params: {q: {loanerEq: "only"}}, as: :json

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item["model"]["name"] }

            assert_equal(%w[PTV], data)
          end
        end

        describe "#index grouped" do
          it "should return list for index" do
            get "/api/v1/fleets/#{starfleet.slug}/vehicles", params: {grouped: true}, as: :json

            assert_response :ok
            json = JSON.parse response.body
            data = json.pluck("name")

            assert_equal(%w[600i Andromeda], data)
          end

          it "should return list with loaners for index" do
            get "/api/v1/fleets/#{starfleet.slug}/vehicles", params: {grouped: true, q: {loanerEq: true}}, as: :json

            assert_response :ok
            json = JSON.parse response.body
            data = json.pluck("name")

            assert_equal(%w[600i Andromeda PTV], data)
          end

          it "should return list with only loaners for index" do
            get "/api/v1/fleets/#{starfleet.slug}/vehicles", params: {grouped: true, q: {loanerEq: "only"}}, as: :json

            assert_response :ok
            json = JSON.parse response.body
            data = json.pluck("name")

            assert_equal(%w[PTV], data)
          end
        end

        describe "#fleetchart" do
          it "should return list for index" do
            get "/api/v1/fleets/#{starfleet.slug}/fleetchart", as: :json

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item["model"]["name"] }

            assert_equal(%w[Andromeda 600i], data)
          end

          it "should return list with loaners for index" do
            get "/api/v1/fleets/#{starfleet.slug}/fleetchart", params: {q: {loanerEq: true}}, as: :json

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item["model"]["name"] }

            assert_equal(%w[Andromeda 600i PTV], data)
          end

          it "should return list with only loaners for index" do
            get "/api/v1/fleets/#{starfleet.slug}/fleetchart", params: {q: {loanerEq: "only"}}, as: :json

            assert_response :ok
            json = JSON.parse response.body
            data = json.map { |item| item["model"]["name"] }

            assert_equal(%w[PTV], data)
          end
        end
      end
    end
  end
end
