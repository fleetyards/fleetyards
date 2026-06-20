# frozen_string_literal: true

json.id funding_goal.id
json.title funding_goal.title
json.description funding_goal.description if funding_goal.description.present?
json.amount_cents funding_goal.amount_cents
json.currency funding_goal.currency
json.effective_from funding_goal.effective_from.iso8601
json.ended_at funding_goal.ended_at.iso8601 if funding_goal.ended_at.present?

json.partial! "api/shared/dates", record: funding_goal
