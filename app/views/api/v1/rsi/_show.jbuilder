# encoding: utf-8
# frozen_string_literal: true

json.username user.username
json.handle user.handle
json.avatar user.avatar
json.title user.title
json.enlisted user.enlisted
json.citizen_record user.citizen_record
json.location user.location
json.languages user.languages
json.orgs do
  json.array! user.orgs, partial: 'api/v1/rsi/org', as: :org
end
