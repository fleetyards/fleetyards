# frozen_string_literal: true

total_amount_cents, currency, total_count, recurring_count, anonymous_count = @stats
current_month_amount_cents, current_month_count = @current_month

json.total_amount_cents total_amount_cents.to_i
json.currency currency || "EUR"
json.total_count total_count.to_i
json.recurring_count recurring_count.to_i
json.anonymous_count anonymous_count.to_i
json.current_month_amount_cents current_month_amount_cents.to_i
json.current_month_count current_month_count.to_i
json.patreon_sync_enabled PatreonSupporterSyncJob.configured?
