# frozen_string_literal: true

require "test_helper"

class AhoyShareTokenTest < ActionDispatch::IntegrationTest
  HEADERS = {"Content-Type" => "application/json", "User-Agent" => "Mozilla/5.0 (Linux; Android 14)"}.freeze

  test "a visit keeps no hangar share token in its landing page or referrer" do
    post "/ahoy/visits",
      params: {
        visit_token: SecureRandom.uuid,
        visitor_token: SecureRandom.uuid,
        landing_page: "https://fleetyards.test/hangar/data/?share=secret&page=2",
        referrer: "https://fleetyards.test/hangar/data/stats/?share=secret"
      }.to_json,
      headers: HEADERS

    assert_response :success

    visit = Ahoy::Visit.sole
    assert_equal "https://fleetyards.test/hangar/data/?share=[FILTERED]&page=2", visit.landing_page
    assert_equal "https://fleetyards.test/hangar/data/stats/?share=[FILTERED]", visit.referrer
  end

  test "a page view keeps no hangar share token in its url" do
    post "/ahoy/events",
      params: {
        events: [{
          id: SecureRandom.uuid,
          name: "$view",
          properties: {url: "https://fleetyards.test/hangar/data/?page=2&share=secret", page: "/hangar/data/"},
          time: Time.current.iso8601
        }]
      }.to_json,
      headers: HEADERS

    assert_response :success

    properties = Ahoy::Event.sole.properties
    assert_equal "https://fleetyards.test/hangar/data/?page=2&share=[FILTERED]", properties["url"]
    assert_equal "/hangar/data/", properties["page"]
  end

  test "the share param is filtered from logged parameters" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

    assert_equal(
      {"share" => "[FILTERED]", "shared" => "true"},
      filter.filter("share" => "secret", "shared" => "true")
    )
  end
end
