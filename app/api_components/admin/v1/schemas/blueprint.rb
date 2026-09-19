# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      # Extends the shared blueprint with what only an admin is shown. Named the
      # same so the admin document's `Blueprint` resolves here while the public
      # one keeps the shared definition.
      class Blueprint < ::Shared::V1::Schemas::Blueprint
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            # 5 of the 1607 recipes in the current build name an output nothing
            # in the catalogues matches. The public payload leaves `craftable`
            # null and says no more; here it is stated, because those rows are
            # the ones most likely to need a decision after a load.
            craftableMissing: {type: :boolean},

            # Null only for a blueprint no load in this environment has ever
            # described, which is a row that should not exist.
            build: {
              anyOf: [::Admin::V1::Schemas::AdminBlueprintBuild, {type: :null}]
            }
          },
          required: %w[craftableMissing]
        })
      end
    end
  end
end
