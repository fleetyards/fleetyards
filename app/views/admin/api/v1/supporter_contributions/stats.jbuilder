# frozen_string_literal: true

total_amount_cents, currency, total_count, recurring_count, anonymous_count = @stats

json.total_amount_cents total_amount_cents.to_i
json.currency currency || "EUR"
json.total_count total_count.to_i
json.recurring_count recurring_count.to_i
json.anonymous_count anonymous_count.to_i
