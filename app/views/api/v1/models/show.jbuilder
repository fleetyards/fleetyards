# frozen_string_literal: true

json.partial! "api/v1/models/model", model: @model, extended: true

# Outside the cached fragment above on purpose: this answer depends on other
# models' docks, and the fragment's key knows only about this one.
json.carried_by @model.carried_by_with_docks do |entry|
  json.slug entry[:carrier].slug
  json.name entry[:carrier].name
  json.dock_type entry[:dock].dock_type
end
