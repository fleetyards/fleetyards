# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ScDataSourcesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/sc-data/sources" do
    get("SC Data Sources") do
      operationId "scDataSources"
      tags "Versions"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/ScDataSources"
      end
    end
  end

  def stub_config(sources:, default: nil)
    Rails.configuration.stubs(:sc_data).returns({sources:, default:}.compact)
  end

  test "GET /sc-data/sources lists the builds a reader can be pointed at" do
    stub_config(sources: {live: "1.0.0", ptu: "1.1.0"}, default: "live")
    create(:model_build, model: create(:model), environment: "live", version: "1.0.0")
    create(:model_build, model: create(:model), environment: "ptu", version: "1.1.0")

    assert_api_response :get, 200 do
      assert_equal %w[live ptu], parsed_body["items"].map { |item| item["environment"] }
      assert_equal [true, false], parsed_body["items"].map { |item| item["default"] }
    end
  end

  # An environment nothing has loaded would answer every question with nothing,
  # so it is not offered rather than served empty.
  test "GET /sc-data/sources leaves out a source nothing has loaded" do
    stub_config(sources: {live: "1.0.0", ptu: "1.1.0"}, default: "live")
    create(:model_build, model: create(:model), environment: "live", version: "1.0.0")

    assert_api_response :get, 200 do
      assert_equal %w[live], parsed_body["items"].map { |item| item["environment"] }
    end
  end

  # The switch pairs a default against a preview, and finds the default by this
  # flag. While a configured build waits for its load the list carries the
  # served build instead, and comparing that against the configured version left
  # nothing flagged -- so the switch found no default and hid itself, in the one
  # window the fallback exists for.
  test "GET /sc-data/sources flags the served build as the default" do
    stub_config(sources: {live: "2.0.0", ptu: "2.1.0"}, default: "live")
    create(:model_build, model: create(:model), environment: "live", version: "1.0.0")
    create(:model_build, model: create(:model), environment: "ptu", version: "2.1.0")
    create(:import, :scdata_all, aasm_state: :finished, version: "1.0.0")
    create(:import, :scdata_all, aasm_state: :finished, version: "2.1.0")

    assert_api_response :get, 200 do
      assert_equal %w[1.0.0 2.1.0], parsed_body["items"].map { |item| item["version"] }
      assert_equal [true, false], parsed_body["items"].map { |item| item["default"] }
    end
  end

  test "GET /sc-data/sources is public" do
    stub_config(sources: {live: "1.0.0"})
    create(:model_build, model: create(:model), environment: "live", version: "1.0.0")

    assert_api_response :get, 200
  end
end
