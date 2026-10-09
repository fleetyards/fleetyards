# frozen_string_literal: true

module Api
  module V1
    class FleetActivitiesController < ::Api::BaseController
      include FleetSubscriptionConcern
      include SquadronVisibilityConcern
      include FleetInventoryScoped

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index]

      before_action :set_fleet

      def index
        authorize! with: FleetActivityPolicy, context: {fleet: @fleet}

        feed = Fleets::ActivityFeed.new(
          user: current_resource_owner,
          memberships: readable_memberships,
          events: readable_events,
          contracts: readable_contracts,
          inventories: readable_inventories
        )

        @entries = feed.entries(
          category: params[:category].presence,
          exclude: Array(params[:exclude]),
          per_category: ActiveModel::Type::Boolean.new.cast(params[:per_category]) || false,
          limit: params[:limit].presence || Fleets::ActivityFeed::DEFAULT_LIMIT
        )
      end

      # Each source answers only where its own list would: the role reads it,
      # the feature is rolled out here and, for the premium ones, the fleet has
      # it. Anything else is left out rather than refused, because the feed is
      # one answer over all of them.
      private def readable_memberships
        return unless allowed_to?(:index?, with: FleetMembershipPolicy, context: {fleet: @fleet})

        @fleet.fleet_memberships.kept.accepted
      end

      private def readable_events
        return unless premium_available?("fleet_mission_builder")
        return unless allowed_to?(:index?, with: FleetEventPolicy, context: {fleet: @fleet})

        scope = @fleet.fleet_events.where(archived_at: nil).where.not(status: "draft")
        return scope if allowed_to?(:manage?, @fleet, with: FleetEventPolicy)

        narrow_to_squadron_access(scope)
      end

      private def readable_contracts
        return unless premium_available?("fleet_contracts")
        return unless allowed_to?(:index?, with: FleetContractPolicy, context: {fleet: @fleet})

        scope = @fleet.fleet_contracts.where.not(aasm_state: "draft")
        return scope if allowed_to?(:manage?, @fleet, with: FleetContractPolicy)

        narrow_to_squadron_access(scope)
      end

      private def readable_inventories
        return unless premium_available?("fleet_logistics")
        return unless allowed_to?(:index?, with: FleetInventoryPolicy, context: {fleet: @fleet})

        readable_fleet_inventories
      end

      private def premium_available?(feature)
        feature_enabled?(feature, @fleet) && !fleet_subscription_missing?(@fleet)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end
    end
  end
end
