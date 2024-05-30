# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class AdminUser
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            username: {type: :string},
            email: {type: :string},
            twoFactorRequired: {type: :boolean},
            twoFactorQrCodeUrl: {type: :string},
            twoFactorProvisioningUrl: {type: :string},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[
            username email twoFactorRequired createdAt updatedAt
          ]
        })
      end
    end
  end
end
