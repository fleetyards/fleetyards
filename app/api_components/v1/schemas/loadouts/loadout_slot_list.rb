# frozen_string_literal: true

module V1
  module Schemas
    module Loadouts
      class LoadoutSlotList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Loadouts::LoadoutSlot
        })
      end
    end
  end
end
