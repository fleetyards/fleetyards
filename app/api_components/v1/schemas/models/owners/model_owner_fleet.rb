# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Owners
        class ModelOwnerFleet
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              fid: {type: :string},
              name: {type: :string},
              slug: {type: :string},
              logo: ::Shared::V1::Schemas::MediaFile,
              total: {type: :integer},
              ownersTotal: {type: :integer},
              members: {type: :array, items: {type: :string}}
            },
            additionalProperties: false,
            required: %w[id fid name slug total ownersTotal members]
          })
        end
      end
    end
  end
end
