# frozen_string_literal: true

json.array! @character_bodies do |body|
  json.key body.key
  json.holo do
    json.partial! "api/v1/shared/file", record: body, attr: :holo
  end
  if body.animations.attached?
    json.animations do
      json.partial! "api/v1/shared/file", record: body, attr: :animations
    end
  else
    json.animations nil
  end
  json.clips body.clips do |clip|
    json.name clip["name"]
    json.static !!clip["static"]
    json.looping !!clip["looping"]
  end
end
