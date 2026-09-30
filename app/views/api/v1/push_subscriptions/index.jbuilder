# frozen_string_literal: true

json.array! @push_subscriptions, partial: "api/v1/push_subscriptions/push_subscription", as: :push_subscription
