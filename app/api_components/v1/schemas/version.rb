# frozen_string_literal: true

module V1
  module Schemas
    class Version
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          version: {type: :string},
          codename: {type: :string},
          announcement: {"$ref": "#/components/schemas/VersionAnnouncement"}
        },
        additionalProperties: false,
        required: %i[version codename]
      })
    end
  end
end
