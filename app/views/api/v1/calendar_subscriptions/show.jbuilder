# frozen_string_literal: true

json.ignore_nil! false

json.enabled @fleet.calendar_feed_enabled?
json.feed_url(
  if @fleet.calendar_feed_enabled?
    api_v1_fleet_calendar_feed_url(
      fleet_slug: @fleet.slug,
      token: @fleet.calendar_feed_token,
      host: Rails.configuration.app.domain,
      protocol: "https"
    )
  end
)
