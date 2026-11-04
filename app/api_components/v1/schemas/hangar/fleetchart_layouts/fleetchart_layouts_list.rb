# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module FleetchartLayouts
        class FleetchartLayoutsList
          include OpenapiRuby::Components::Base

          schema({type: :array, items: FleetchartLayout})
        end
      end
    end
  end
end
