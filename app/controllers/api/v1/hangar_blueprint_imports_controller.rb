# frozen_string_literal: true

module Api
  module V1
    # Importing the blueprints a player received in game, read from their game
    # logs. The logs are parsed in the browser; only blueprint names and the
    # chosen slugs reach these actions.
    class HangarBlueprintImportsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?

      # A read the review step is built from, so nothing is written until the
      # user has seen what each name resolves to.
      def match
        authorize! ::Blueprint, to: :own?

        render json: ::Blueprints::LogNameMatcher.new(current_resource_owner).match(match_params.fetch(:names, []))
      end

      def create
        authorize! ::Blueprint, to: :own?

        import = ::Imports::BlueprintLogImport.record!(
          current_resource_owner,
          import_params.fetch(:slugs, []),
          import_params.fetch(:unmatched_names, [])
        )

        render json: {
          imported: import.imported_count,
          unchanged: import.unchanged_count,
          importId: import.id
        }
      end

      private def match_params
        params.permit(names: [])
      end

      private def import_params
        params.permit(slugs: [], unmatched_names: [])
      end
    end
  end
end
