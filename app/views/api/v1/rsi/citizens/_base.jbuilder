# encoding: utf-8
# frozen_string_literal: true

json.username citizen.username
json.handle citizen.handle
json.avatar citizen.avatar
json.title citizen.title
json.enlisted citizen.enlisted
json.citizen_record citizen.citizen_record
json.location citizen.location
json.languages citizen.languages
json.orgs do
  json.array! citizen.orgs, partial: 'api/v1/rsi/orgs/base', as: :org
end
