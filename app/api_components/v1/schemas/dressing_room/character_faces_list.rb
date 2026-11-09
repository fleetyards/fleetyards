# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class CharacterFacesList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::DressingRoom::CharacterFace
        })
      end
    end
  end
end
