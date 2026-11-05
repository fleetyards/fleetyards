# frozen_string_literal: true

module V1
  module Schemas
    class FactionsList
      include OpenapiRuby::Components::Base

      schema({type: :array, items: ::V1::Schemas::Faction})
    end
  end
end
