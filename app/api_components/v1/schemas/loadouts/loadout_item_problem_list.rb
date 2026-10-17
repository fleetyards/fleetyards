# frozen_string_literal: true

module V1
  module Schemas
    module Loadouts
      class LoadoutItemProblemList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Loadouts::LoadoutItemProblem
        })
      end
    end
  end
end
