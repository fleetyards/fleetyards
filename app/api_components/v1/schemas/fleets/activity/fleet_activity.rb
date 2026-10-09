# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Activity
        class FleetActivity
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string},
              kind: ::V1::Schemas::Enums::FleetActivityKindEnum,
              category: ::V1::Schemas::Enums::FleetActivityCategoryEnum,
              occurredAt: {type: :string, format: "date-time"},
              involvesViewer: {type: :boolean},
              actor: {anyOf: [::V1::Schemas::Fleets::Activity::FleetActivityActor, {type: :null}]},
              subject: ::V1::Schemas::Fleets::Activity::FleetActivitySubject,
              inventory: {anyOf: [::V1::Schemas::Fleets::Activity::FleetActivityInventory, {type: :null}]}
            },
            required: %w[id kind category occurredAt involvesViewer subject]
          })
        end
      end
    end
  end
end
