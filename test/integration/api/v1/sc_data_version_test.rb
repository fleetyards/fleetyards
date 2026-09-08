# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ScDataVersionTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/sc-data/version" do
    get("SC Data Version") do
      operationId "scDataVersion"
      tags "Versions"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/ScDataVersion"
      end
    end
  end

  setup do
    create(:import, :scdata_all, aasm_state: :finished, version: "1.0.0")
  end

  test "GET /sc-data/version returns the finished import version" do
    assert_api_response :get, 200
  end

  # It used to answer with whichever load finished last, whatever source that
  # was for. With two configured that is the wrong one half the time, so it
  # answers for the source in force -- and a version names its environment, so
  # no environment column on the ledger is needed to ask it.
  test "GET /sc-data/version answers for the source in force" do
    Rails.configuration.stubs(:sc_data).returns({
      sources: {live: "3.24.0", ptu: "3.24.1-ptu.2"}, default: "live"
    })
    create(:import, :scdata_all, version: "3.24.0", aasm_state: "finished")
    create(:import, :scdata_all, version: "3.24.1-ptu.2", aasm_state: "finished")

    # ptu finished last, so the old reading would have served it to everyone.
    assert_api_response :get, 200 do
      assert_equal "3.24.0", parsed_body["version"]
    end
  end

  test "GET /sc-data/version has nothing to report for a source no load finished" do
    Rails.configuration.stubs(:sc_data).returns({sources: {live: "3.24.0"}, default: "live"})

    assert_api_response :get, 200 do
      assert_nil parsed_body["version"]
    end
  end
end
