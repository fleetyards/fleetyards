# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class AdminUserFleet
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            fleetId: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            fid: {type: :string},
            logo: {"$ref": "#/components/schemas/MediaFile"},
            role: {type: :string},
            permanent: {type: :boolean},
            primary: {type: :boolean},
            status: {type: :string},
            membersCount: {type: :integer},
            acceptedAt: {type: :string, format: "date-time"},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id fleetId name slug permanent primary status membersCount createdAt updatedAt]
        })
      end
    end
  end
end
