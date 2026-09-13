# frozen_string_literal: true

module V1
  module Schemas
    # What a run did, as lists a person can read, rather than the raw `output`
    # -- half of which is ids. Every key is optional: the shape differs per
    # import type, and an empty list is omitted rather than sent as `[]`.
    class ImportDetails
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          imported: {type: :array, items: {type: :string}},
          found: {type: :array, items: {type: :string}},
          movedToWanted: {type: :array, items: {type: :string}},
          deleted: {type: :array, items: {type: :string}},
          grouped: {type: :array, items: {type: :string}},
          unchanged: {type: :array, items: {type: :string}},
          missing: {type: :array, items: {type: :string}},
          missingComponents: {type: :array, items: {type: :string}},
          missingUpgrades: {type: :array, items: {type: :string}}
        },
        additionalProperties: false
      })
    end
  end
end
