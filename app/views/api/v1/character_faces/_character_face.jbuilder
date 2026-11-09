# frozen_string_literal: true

json.id character_face.id
json.name character_face.name
json.token character_face.token
json.body character_face.body
json.dna_stamp character_face.dna_stamp
json.gender_hash character_face.gender_hash
json.format_version character_face.format_version
json.game_version character_face.game_version
json.file do
  json.partial! "api/v1/shared/file", record: character_face, attr: :chf
end
json.partial! "api/shared/dates", record: character_face
