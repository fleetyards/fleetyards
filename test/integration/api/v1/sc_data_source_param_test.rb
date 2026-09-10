# frozen_string_literal: true

require "test_helper"

# `source=ptu` puts that build in force for the whole action, so every model,
# scope and ransacker underneath answers from it without being told.
class Api::V1::ScDataSourceParamTest < ActionDispatch::IntegrationTest
  setup do
    Rails.configuration.stubs(:sc_data).returns({sources: {live: "1.0.0", ptu: "1.1.0"}, default: "live"})

    @commodity = create(:commodity, :without_build, name: "Column Name")
    @commodity.builds.create!(environment: "live", version: "1.0.0", name: "Live Name")
    @commodity.builds.create!(environment: "ptu", version: "1.1.0", name: "PTU Name")
  end

  test "a request without a source reads the default build" do
    get "/api/v1/commodities"

    assert_equal ["Live Name"], response.parsed_body["items"].map { |item| item["name"] }
  end

  test "source=ptu reads the ptu build" do
    get "/api/v1/commodities", params: {source: "ptu"}

    assert_equal ["PTU Name"], response.parsed_body["items"].map { |item| item["name"] }
  end

  # A source the config declares but nothing has loaded is not accepted, so a
  # reader gets the default rather than an empty catalogue.
  test "a source nothing has loaded falls back to the default" do
    Rails.configuration.stubs(:sc_data).returns({sources: {live: "1.0.0", nowhere: "9.9.9"}, default: "live"})

    get "/api/v1/commodities", params: {source: "nowhere"}

    assert_equal ["Live Name"], response.parsed_body["items"].map { |item| item["name"] }
  end

  # A bookmarked link must not break the day an environment is retired.
  test "a source that is not configured at all falls back too" do
    get "/api/v1/commodities", params: {source: "made-up"}

    assert_equal ["Live Name"], response.parsed_body["items"].map { |item| item["name"] }
  end

  # `ScData::Current` is reset for us at the end of every request, so a source
  # set for one cannot leak into the next on the same thread.
  test "a source does not leak into the next request" do
    get "/api/v1/commodities", params: {source: "ptu"}
    assert_equal ["PTU Name"], response.parsed_body["items"].map { |item| item["name"] }

    get "/api/v1/commodities"
    assert_equal ["Live Name"], response.parsed_body["items"].map { |item| item["name"] },
      "the next request went back to the default"
  end

  # A cached fragment must not be shared between the two sources. `json.cache!`
  # keys on the record, and a record backed by a build says something different
  # per source -- so without the source in the key the first request to warm an
  # entry answers for both. Both orders, because the bug is whichever source
  # got there first.
  test "a cached fragment is not shared between sources" do
    with_fragment_caching do
      get "/api/v1/commodities"
      assert_equal ["Live Name"], response.parsed_body["items"].map { |item| item["name"] }

      get "/api/v1/commodities", params: {source: "ptu"}
      assert_equal ["PTU Name"], response.parsed_body["items"].map { |item| item["name"] },
        "the ptu request was served the live build's cached fragment"
    end
  end

  test "a cached fragment warmed by ptu does not answer for the default" do
    with_fragment_caching do
      get "/api/v1/commodities", params: {source: "ptu"}
      assert_equal ["PTU Name"], response.parsed_body["items"].map { |item| item["name"] }

      get "/api/v1/commodities"
      assert_equal ["Live Name"], response.parsed_body["items"].map { |item| item["name"] },
        "the default was served the ptu build's cached fragment"
    end
  end

  # The model fragment is the one every ships list renders, and its facts come
  # from the build.
  test "a cached model fragment is not shared between sources" do
    model_with_builds

    with_fragment_caching do
      get "/api/v1/models"
      assert_equal [100.0], response.parsed_body["items"].map { |item| item.dig("speeds", "scmSpeed") }

      get "/api/v1/models", params: {source: "ptu"}
      assert_equal [200.0], response.parsed_body["items"].map { |item| item.dig("speeds", "scmSpeed") },
        "the ptu request was served the live build's cached model"
    end
  end

  # The vehicle fragments key on `vehicle.model` rather than on a record of
  # their own, which is the shape a grep for the catalogues would miss.
  test "a cached vehicle fragment is not shared between sources" do
    user = create(:user)
    vehicle = create(:vehicle, model: model_with_builds, user:)

    sign_in user

    with_fragment_caching do
      get "/api/v1/vehicles/#{vehicle.id}"
      assert_equal 100.0, response.parsed_body.dig("model", "speeds", "scmSpeed")

      get "/api/v1/vehicles/#{vehicle.id}", params: {source: "ptu"}
      assert_equal 200.0, response.parsed_body.dig("model", "speeds", "scmSpeed"),
        "the ptu request was served the live build's cached vehicle"
    end
  end

  test "the source reaches a filter, not just a reader" do
    get "/api/v1/commodities", params: {source: "ptu", q: {nameCont: "PTU"}}
    assert_equal ["PTU Name"], response.parsed_body["items"].map { |item| item["name"] }

    get "/api/v1/commodities", params: {source: "ptu", q: {nameCont: "Live"}}
    assert_empty response.parsed_body["items"]
  end

  # The column is deliberately a value neither build carries, so a payload that
  # fell through to it cannot be mistaken for either side.
  private def model_with_builds
    model = create(:model, scm_speed: 1)
    model.builds.create!(environment: "live", version: "1.0.0", scm_speed: 100)
    model.builds.create!(environment: "ptu", version: "1.1.0", scm_speed: 200)
    model
  end
end
