# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Bodykits
        class ModelBodykitList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: ::V1::Schemas::Models::Bodykits::ModelBodykit
          })
        end
      end
    end
  end
end
