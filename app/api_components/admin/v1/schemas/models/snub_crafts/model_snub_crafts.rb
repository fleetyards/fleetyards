# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module SnubCrafts
          class ModelSnubCrafts < ::Shared::V1::Schemas::BaseList
            include OpenapiRuby::Components::Base

            schema({
              properties: {
                items: {type: :array, items: ::Admin::V1::Schemas::Models::SnubCrafts::ModelSnubCraft}
              },
              required: %w[items]
            })
          end
        end
      end
    end
  end
end
