# frozen_string_literal: true

json.array! @character_bodies do |body|
  json.key body.key
  json.holo do
    json.partial! "api/v1/shared/file", record: body, attr: :holo
  end
end
