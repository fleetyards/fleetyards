# frozen_string_literal: true

json.array! @character_faces, partial: "api/v1/character_faces/character_face", as: :character_face
