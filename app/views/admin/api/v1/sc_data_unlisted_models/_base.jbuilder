# frozen_string_literal: true

entry = sc_data_unlisted_model

json.id entry.id
json.identifier entry.identifier
json.name entry.name

# The export prefixes the manufacturer and Fleetyards does not, so this is what
# a model made from the entry would actually be called.
json.suggested_name entry.suggested_name

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

# A ship of that name already in the catalogue. Only a quarter of models carry an
# `sc_key`, so one whose identifier comes from its slug lands in this list even
# though it exists -- this is what stops a second being made from it.
existing_model = entry.existing_model
if existing_model.present?
  json.existing_model do
    json.id existing_model.id
    json.name existing_model.name
    json.slug existing_model.slug
  end
else
  json.existing_model nil
end

# The livery is already on the ship this extends, so the entry only needs marking.
existing_paint = entry.existing_paint
if existing_paint.present?
  json.existing_paint do
    json.id existing_paint.id
    json.name existing_paint.name
    json.slug existing_paint.slug
  end
else
  json.existing_paint nil
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
