# frozen_string_literal: true

json.cache! ['v1', user] do
  json.id user.id
  json.email user.email
  json.username user.username
  json.avatar user.avatar.small.url
  json.is_admin user.admin?
  json.sale_notify user.sale_notify
  json.public_hangar user.public_hangar
  json.fleets do
    json.array! user.fleets.not_declined, partial: 'api/v1/fleets/minimal', as: :fleet
  end
  json.partial! 'api/shared/dates', record: user
end
