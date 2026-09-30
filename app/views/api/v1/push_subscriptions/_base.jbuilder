# frozen_string_literal: true

# The schema requires these keys even when they are null.
json.ignore_nil! false

user_agent = UserAgent.parse(push_subscription.user_agent.to_s) if push_subscription.user_agent.present?

json.id push_subscription.id
json.browser user_agent&.browser.presence
json.os user_agent&.os.presence
json.last_delivered_at push_subscription.last_delivered_at&.utc&.iso8601
json.created_at push_subscription.created_at.utc.iso8601
