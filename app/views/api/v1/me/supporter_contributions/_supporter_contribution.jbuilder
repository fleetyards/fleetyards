# frozen_string_literal: true

json.id supporter_contribution.id
json.amount_cents supporter_contribution.amount_cents
json.currency supporter_contribution.currency
json.started_at supporter_contribution.started_at
json.ended_at supporter_contribution.ended_at
json.recurring supporter_contribution.recurring

# Omitted entirely rather than rendered null, which is the shape FleetRef
# documents and what `api/v1/tours/_base` already does for the same component.
if supporter_contribution.fleet.present?
  json.fleet do
    json.id supporter_contribution.fleet.id
    json.name supporter_contribution.fleet.name
    json.slug supporter_contribution.fleet.slug

    if supporter_contribution.fleet.logo.attached?
      json.logo do
        json.partial! "api/v1/shared/file", record: supporter_contribution.fleet, attr: :logo
      end
    end
  end
end
