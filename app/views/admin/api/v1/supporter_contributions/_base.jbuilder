# frozen_string_literal: true

json.id supporter_contribution.id
json.name supporter_contribution.name if supporter_contribution.name.present?
json.amount_cents supporter_contribution.amount_cents
json.currency supporter_contribution.currency
json.anonymous supporter_contribution.anonymous
json.recurring supporter_contribution.recurring
json.source supporter_contribution.source
json.patreon_member_id supporter_contribution.patreon_member_id if supporter_contribution.patreon_member_id.present?
json.started_at supporter_contribution.started_at.iso8601
json.ended_at supporter_contribution.ended_at&.iso8601 if supporter_contribution.ended_at.present?
json.note supporter_contribution.note if supporter_contribution.note.present?

json.partial! "api/shared/dates", record: supporter_contribution
