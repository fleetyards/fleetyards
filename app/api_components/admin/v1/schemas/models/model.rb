# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        class Model < ::V1::Schemas::Models::Model
          include OpenapiRuby::Components::Base

          schema({
            properties: {
              hidden: {type: :boolean},
              active: {type: :boolean},
              scKey: {type: :string},
              positionsNeedCuration: {type: :boolean},
              scLength: {type: :number},
              scBeam: {type: :number},
              scHeight: {type: :number},
              media: AdminModelMedia
            },
            required: %w[hidden active media]
          })
        end
      end
    end
  end
end
