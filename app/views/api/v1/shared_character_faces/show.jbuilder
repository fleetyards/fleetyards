# frozen_string_literal: true

json.token @character_face.token
json.name @character_face.name
json.body @character_face.body
json.file do
  json.partial! "api/v1/shared/file", record: @character_face, attr: :chf
end
# Served as resolved: its keys are data -- port names, headwear tags, three.js
# and game parameter names -- and camelizing them would break the lookups.
json.deep_format_keys! false
json.character @character_face.character
