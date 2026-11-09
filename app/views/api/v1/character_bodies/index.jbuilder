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
  json.hold_poses body.hold_poses do |pose|
    # Merged rather than set: `Jbuilder.ignore_nil` would drop the null weight
    # of the hold for no core, and leave the required key missing.
    json.merge!(armor_weight: pose["armor_weight"]) # standard:disable Performance/RedundantMerge -- a Jbuilder, not a Hash: `[]=` would drop the nil
    json.clip pose["clip"]
  end
  json.skin_tone body.skin_tone
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
  # Served as resolved: its keys are data -- port names, headwear tags, three.js
  # and game parameter names -- and camelizing them would break the lookups.
  json.deep_format_keys! false
  json.default_character body.character(@context)
end
