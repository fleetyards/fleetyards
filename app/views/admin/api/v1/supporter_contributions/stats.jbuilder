# frozen_string_literal: true

json.total_amount_cents @stats_scope.sum(:amount_cents)
json.currency @stats_scope.pick(:currency) || "EUR"
json.total_count @stats_scope.count
json.recurring_count @stats_scope.where(recurring: true).count
json.anonymous_count @stats_scope.where(anonymous: true).count
