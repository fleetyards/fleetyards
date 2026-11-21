# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class BlueprintLogMatchList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Hangar::BlueprintLogMatch
        })
      end
    end
  end
end
