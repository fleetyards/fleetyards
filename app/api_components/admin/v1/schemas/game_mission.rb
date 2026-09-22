# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      # Extends the shared mission with what only an admin is shown. Named the
      # same so the admin document's `GameMission` resolves here while the
      # public one keeps the shared definition.
      class GameMission < ::Shared::V1::Schemas::GameMission
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            # 74 of the 2,536 contracts have no name anywhere -- no `Title`
            # override, and a template whose `displayString` is uninitialised.
            # The public catalogue leaves them out entirely; here it is stated,
            # because those are the rows most likely to need a look after a load.
            unnamed: {type: :boolean},

            # The pools this mission hands out, by ref. The public payload
            # resolves them to recipes; here the refs themselves are what a
            # person chasing a load through the export needs.
            blueprintPoolRefs: {type: :array, items: {type: :string}},

            # Which build is answering for the row, and whether it is the one we
            # are on. A row rendering off `last_build` is one the current build
            # dropped, which is worth seeing directly rather than inferring.
            build: {
              anyOf: [::Admin::V1::Schemas::AdminGameMissionBuild, {type: :null}]
            }
          },
          required: %w[unnamed]
        })
      end
    end
  end
end
