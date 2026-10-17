# frozen_string_literal: true

module V1
  module Schemas
    module Loadouts
      class LoadoutOptionList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Loadouts::LoadoutOption
        })
      end
    end
  end
end
