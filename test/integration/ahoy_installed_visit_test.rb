# frozen_string_literal: true

require "test_helper"

class AhoyInstalledVisitTest < ActionDispatch::IntegrationTest
  test "a page view from the installed app marks the visit installed" do
    track_view(installed: true)

    assert_predicate Ahoy::Visit.sole, :installed?
  end

  test "a page view from the browser leaves the visit uninstalled" do
    track_view

    assert_not_predicate Ahoy::Visit.sole, :installed?
  end

  test "a later browser view keeps the visit installed" do
    track_view(installed: true)
    track_view

    assert_predicate Ahoy::Visit.sole, :installed?
  end

  test "another event carrying the flag does not mark the visit" do
    track_event("$submit", installed: true)

    assert_not_predicate Ahoy::Visit.sole, :installed?
  end

  private def track_view(**properties)
    track_event("$view", page: "/ships/", **properties)
  end

  private def track_event(name, **properties)
    post "/ahoy/events",
      params: {events: [{id: SecureRandom.uuid, name:, properties:, time: Time.current.iso8601}]}.to_json,
      headers: {"Content-Type" => "application/json", "User-Agent" => "Mozilla/5.0 (Linux; Android 14)"}

    assert_response :success
  end
end
