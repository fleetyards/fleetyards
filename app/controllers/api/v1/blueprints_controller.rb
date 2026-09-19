# frozen_string_literal: true

module Api
  module V1
    class BlueprintsController < ::Api::PublicBaseController
      include BlueprintFiltersConcern

      skip_verify_authorized only: %i[index show]

      # The catalogue is public; saying you hold a recipe is not. Guarded the
      # way every mixed controller here is -- a session passes straight
      # through, and anything else has to carry a token with the scope.
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[own unown]

      after_action -> { pagination_header(:blueprints) }, only: [:index]

      # One recipe, with everything a crafter is actually asking: what it makes,
      # what each slot costs, how good the material has to be, and which of that
      # moves which stat.
      def show
        slug = params[:slug].to_s.downcase

        @blueprint = Blueprint.includes(
          :craftable, build: [{cost_slots: [{options: :commodity}, :modifiers]}, :sources]
        ).find_by!(slug:)

        @owned_blueprint_ids = owned_ids_for([@blueprint])
      end

      def index
        @blueprints = filtered_blueprints
          .page(params[:page])
          .per(per_page(Blueprint))

        # After pagination, so it asks about the 60 rows being rendered rather
        # than the 1,607.
        @owned_blueprint_ids = owned_ids_for(@blueprints)
      end

      # Idempotent on purpose: holding a recipe is a state, not an event, so
      # marking one twice is the same answer rather than a duplicate row or a
      # validation error a client has to interpret.
      def own
        blueprint = find_blueprint

        authorize! blueprint

        UserBlueprint.find_or_create_by!(user_id: current_resource_owner.id, blueprint_id: blueprint.id)

        head :no_content
      rescue ActiveRecord::RecordNotUnique
        # Two clicks landing together. The row exists either way, which is what
        # was asked for.
        head :no_content
      end

      def unown
        blueprint = find_blueprint

        authorize! blueprint, to: :unown?

        UserBlueprint.where(user_id: current_resource_owner.id, blueprint_id: blueprint.id).destroy_all

        head :no_content
      end

      private def find_blueprint
        Blueprint.find_by!(slug: params[:slug].to_s.downcase)
      end
    end
  end
end
