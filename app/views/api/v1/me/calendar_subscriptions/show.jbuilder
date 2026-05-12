# frozen_string_literal: true

json.ignore_nil! false

json.enabled @user.calendar_feed_enabled?
json.feed_url(
  if @user.calendar_feed_enabled?
    api_v1_me_calendar_feed_url(
      token: @user.calendar_feed_token,
      host: Rails.configuration.app.domain,
      protocol: "https"
    )
  end
)
