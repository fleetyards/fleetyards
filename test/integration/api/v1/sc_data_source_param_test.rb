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

  test "the source reaches a filter, not just a reader" do
    get "/api/v1/commodities", params: {source: "ptu", q: {nameCont: "PTU"}}
    assert_equal ["PTU Name"], response.parsed_body["items"].map { |item| item["name"] }

    get "/api/v1/commodities", params: {source: "ptu", q: {nameCont: "Live"}}
    assert_empty response.parsed_body["items"]
  end
end
