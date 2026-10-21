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
        only: %i[own unown want unwant]

      after_action -> { pagination_header(:blueprints) }, only: [:index]

      # One recipe, with everything a crafter is actually asking: what it makes,
      # what each slot costs, how good the material has to be, and which of that
      # moves which stat.
      def show
        slug = params[:slug].to_s.downcase

        @blueprint = Blueprint.includes(
          :craftable, build: [{cost_slots: [{options: :commodity}, :modifiers]}, :sources]
        ).find_by!(slug:)

        @owned_blueprint_ids, @wanted_blueprint_ids = marked_ids_for([@blueprint])
      end

      def index
        @blueprints = filtered_blueprints
          .page(page_params)
          .per(per_page(Blueprint))

        # After pagination, so it asks about the 60 rows being rendered rather
        # than the 1,607.
        @owned_blueprint_ids, @wanted_blueprint_ids = marked_ids_for(@blueprints)
      end

      # Idempotent on purpose: holding a recipe is a state, not an event, so
      # marking one twice is the same answer rather than a duplicate row or a
      # validation error a client has to interpret.
      #
      # Owning a recipe on the wishlist takes it off the wishlist: the marker
      # is updated rather than a second one written.
      def own
        blueprint = find_blueprint

        authorize! blueprint

        mark(blueprint, wanted: false)

        head :no_content
      end

      # Only drops a held marker: unowning something on the wishlist would
      # otherwise quietly take it off the wishlist too.
      def unown
        blueprint = find_blueprint

        authorize! blueprint, to: :unown?

        UserBlueprint.owned.where(user_id: current_resource_owner.id, blueprint_id: blueprint.id).destroy_all

        head :no_content
      end

      # Wanting a held recipe moves it to the wishlist -- it was lost, in a
      # wipe say -- in one write, so there is no moment where it is neither.
      def want
        blueprint = find_blueprint

        authorize! blueprint, to: :want?

        mark(blueprint, wanted: true)

        head :no_content
      end

      def unwant
        blueprint = find_blueprint

        authorize! blueprint, to: :unwant?

        UserBlueprint.wanted.where(user_id: current_resource_owner.id, blueprint_id: blueprint.id).destroy_all

        head :no_content
      end

      # A marker changing state starts its time in the new one: the fleet lists
      # holders longest first, and a recipe wanted for months and acquired
      # today has been held since today.
      private def mark(blueprint, wanted:)
        marker = UserBlueprint.find_or_initialize_by(user_id: current_resource_owner.id, blueprint_id: blueprint.id)

        return if marker.persisted? && marker.wanted == wanted

        marker.update!(wanted:, created_at: Time.current)
      rescue ActiveRecord::RecordNotUnique
        # Two requests landing together, and the other one inserted first --
        # possibly in the other state. The last one asked for is the answer.
        UserBlueprint.where(user_id: current_resource_owner.id, blueprint_id: blueprint.id)
          .update_all(wanted:, created_at: Time.current, updated_at: Time.current)
      end

      private def find_blueprint
        Blueprint.find_by!(slug: params[:slug].to_s.downcase)
      end
    end
  end
end
