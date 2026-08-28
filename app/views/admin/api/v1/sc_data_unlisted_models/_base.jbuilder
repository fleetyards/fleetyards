# frozen_string_literal: true

entry = sc_data_unlisted_model

json.id entry.id
json.identifier entry.identifier
json.name entry.name

# How the export's version compares to the ship it extends. Descriptive rather
# than a verdict: the game files never say whether a player can own something.
json.comparison entry.comparison
json.decision entry.decision
json.decided_at entry.decided_at

json.first_seen_version entry.first_seen_version
json.last_seen_version entry.last_seen_version
json.environment entry.last_seen_environment

json.manufacturer_code entry.manufacturer_code

# Blank when the identifier names a prefix no ship in the catalogue uses -- a
# new company, or a file that is not a ship at all.
manufacturer = entry.manufacturer
if manufacturer.present?
  json.manufacturer do
    json.id manufacturer.id
    json.name manufacturer.name
    json.code manufacturer.code
    json.slug manufacturer.slug
  end
else
  json.manufacturer nil
end

if entry.base_model.present?
  json.base_model do
    json.id entry.base_model.id
    json.name entry.base_model.name
    json.slug entry.base_model.slug
  end
else
  json.base_model nil
end

if entry.model.present?
  json.model do
    json.id entry.model.id
    json.name entry.model.name
    json.slug entry.model.slug
  end
else
  json.model nil
end

json.partial! "api/shared/dates", record: entry
