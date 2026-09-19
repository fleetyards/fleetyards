# frozen_string_literal: true

module Api
  module V1
    # What a fleet can craft between them: the recipes its members hold, and
    # who holds each one.
    #
    # Read through a join rather than out of a `fleet_blueprints` table. Ships
    # are denormalised because a hangar is large and its rows carry per-vehicle
    # state a filter has to re-evaluate; a marker is one row with nothing on it,
    # so a join answers the same question with no sync job to fall out of step.
    class FleetBlueprintsController < ::Api::BaseController
      include BlueprintFiltersConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?

      before_action :set_fleet

      after_action -> { pagination_header(:blueprints) }, only: %i[index]

      def index
        authorize! with: FleetBlueprintPolicy, context: {fleet: @fleet}

        @blueprints = filtered_blueprints(Blueprint.owned_by(sharing_memberships.select(:user_id)))
          .page(params[:page])
          .per(per_page(Blueprint))

        # Both after pagination: the page being rendered is what either of them
        # is asked about.
        @owned_blueprint_ids = owned_ids_for(@blueprints)
        @owners = owners_for(@blueprints)
      end

      # The members who let this fleet see what they hold.
      #
      # `blueprints_filter_all` rather than "not hide", so a position added
      # later has to be opted into rather than silently counting as sharing.
      private def sharing_memberships
        @sharing_memberships ||= @fleet.fleet_memberships.kept
          .where(aasm_state: "accepted")
          .blueprints_filter_all
      end

      # Who holds each of these recipes, keyed by blueprint.
      #
      # Two queries for the whole page: the memberships once, so a name, a
      # nickname and an avatar come from the fleet's own view of the person
      # rather than from the bare user, and the markers once.
      private def owners_for(blueprints)
        return {} if blueprints.empty?

        memberships = sharing_memberships.includes(:user).index_by(&:user_id)

        UserBlueprint
          .where(blueprint_id: blueprints.map(&:id), user_id: memberships.keys)
          .order(:created_at)
          .group_by(&:blueprint_id)
          .transform_values { |marks| marks.filter_map { |mark| memberships[mark.user_id] } }
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end
    end
  end
end
