# frozen_string_literal: true

module V1
  module Schemas
    module Models
      class ModelDefensesList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ModelDefense
        })
      end
    end
  end
end
