# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class OauthApplication
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            uid: {type: :string},
            secret: {type: :string},
            confidential: {type: :boolean},
            redirectUri: {type: :string},
            scopes: {type: :string},
            ownerName: {type: :string},
            ownerId: {type: :string, format: :uuid},
            state: {type: :string, enum: %w[pending approved rejected]},
            rejectionReason: {type: [:string, :null]},
            approvedAt: {type: [:string, :null], format: "date-time"},
            rejectedAt: {type: [:string, :null], format: "date-time"},
            reviewedByName: {type: [:string, :null]},
            authorizedUsersCount: {type: :integer, description: "People holding an unrevoked access token"},
            logo: ::Shared::V1::Schemas::MediaFile,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name uid secret confidential redirectUri scopes state authorizedUsersCount createdAt updatedAt]
        })
      end
    end
  end
end
