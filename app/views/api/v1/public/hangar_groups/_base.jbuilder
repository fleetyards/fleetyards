# frozen_string_literal: true

json.id group.id
json.name group.name
json.slug group.slug
json.color group.color
json.sort group.sort
json.partial! "api/shared/dates", record: group
