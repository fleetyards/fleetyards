# frozen_string_literal: true

module V1
  module Schemas
    # A contribution as its own payer sees it: enough to tell two of them apart,
    # plus the one thing they may change -- which fleet it is for.
    #
    # Named `My…` rather than `SupporterContribution` because that name is
    # already an admin component, and a name living in two scopes has to be
    # referenced as a late-bound string. A distinct name keeps the class form,
    # where a typo is a NameError instead of a dangling `$ref`.
    #
    # No `source`: naming the platform would mean reaching for the source enum,
    # which is admin-scoped and being reworked in #4976. Amount and date are
    # enough to identify a contribution, and the enum can be added once it has
    # settled.
    class MySupporterContribution
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          amountCents: {type: :integer},
          currency: {type: :string},
          startedAt: {type: :string, format: :date},
          endedAt: {type: [:string, :null], format: :date},
          recurring: {type: :boolean},
          # Absent rather than null when nothing is nominated, which is the
          # shape `FleetRef` documents for every other owner.
          fleet: ::V1::Schemas::FleetRef
        },
        additionalProperties: false,
        required: %w[id amountCents currency startedAt recurring]
      })
    end
  end
end
