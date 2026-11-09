# frozen_string_literal: true

json.array! @character_bodies do |body|
  json.key body.key
  json.holo do
    json.partial! "api/v1/shared/file", record: body, attr: :holo
  end
  if body.holo_textured.attached?
    json.holo_textured do
      json.partial! "api/v1/shared/file", record: body, attr: :holo_textured
    end
  else
    json.holo_textured nil
  end
  if body.animations.attached?
    json.animations do
      json.partial! "api/v1/shared/file", record: body, attr: :animations
    end
  else
    json.animations nil
  end
  json.weapon_in_hand body.weapon_in_hand
  json.lighting body.lighting
  json.clips body.clips do |clip|
    json.name clip["name"]
    json.static !!clip["static"]
    json.looping !!clip["looping"]
  end
  json.skin_tone body.skin_tone
  if @default_eyes
    json.default_eyes do
      json.iris @default_eyes["iris"]
      json.iris_color @default_eyes["iris_color"]
    end
  else
    json.default_eyes nil
  end
  if body.face_library?
    json.face_library do
      json.library body.face_library
      json.index { json.partial! "api/v1/shared/file", record: body, attr: :face_index }
      json.positions { json.partial! "api/v1/shared/file", record: body, attr: :face_positions }
      json.normals { json.partial! "api/v1/shared/file", record: body, attr: :face_normals }
    end
  else
    json.face_library nil
  end
end
