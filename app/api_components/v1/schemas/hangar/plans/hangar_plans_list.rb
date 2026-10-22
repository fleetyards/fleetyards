# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlansList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: ::V1::Schemas::Hangar::Plans::HangarPlanListItem
          })
        end
      end
    end
  end
end
