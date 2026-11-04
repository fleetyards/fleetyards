# frozen_string_literal: true

module Api
  module V1
    # The site search over one fleet. Each section answers only where the
    # caller could open its list: the same permission, feature and subscription
    # gates, and the same visibility rules, as the list's own endpoint.
    class FleetSearchController < ::Api::BaseController
      include FleetContractScoped
      include FleetEventScoped
      include FleetInventoryScoped
      include FleetSubscriptionConcern
      include SquadronVisibilityConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?
      before_action :set_fleet

      def index
        @groups = ScopedSearch.new(sources).call(params[:q])

        render "api/v1/search/index"
      end

      private def sources
        [member_source, event_source, contract_source, inventory_source].compact
      end

      private def member_source
        return unless allowed_to?(:index?, with: FleetMembershipPolicy, context: {fleet: @fleet})

        ScopedSearch::Source.new(
          type: "FleetMembership",
          scope: @fleet.fleet_memberships.kept.includes(:user).references(:user).order("users.username"),
          filter: :user_username_or_user_display_name_or_nickname_cont,
          item: lambda { |member|
            ScopedSearch.result(
              type: "FleetMembership", name: member.user.username, slug: member.user.username,
              detail: member.nickname.presence
            )
          }
        )
      end

      private def event_source
        return unless readable?(FleetEventPolicy, "fleet_mission_builder", :events)

        ScopedSearch::Source.new(
          type: "FleetEvent",
          scope: reachable_fleet_events(@fleet.fleet_events.where(archived_at: nil)).order(:title),
          filter: :title_cont,
          item: ->(event) { ScopedSearch.result(type: "FleetEvent", name: event.title, slug: event.slug) }
        )
      end

      private def contract_source
        return unless readable?(FleetContractPolicy, "fleet_contracts", :contracts)

        ScopedSearch::Source.new(
          type: "FleetContract",
          scope: FleetContract.where(id: visible_fleet_contracts.select(:id)).order(:title),
          filter: :title_cont,
          item: ->(contract) { ScopedSearch.result(type: "FleetContract", name: contract.title, slug: contract.slug) }
        )
      end

      private def inventory_source
        return unless readable?(FleetInventoryItemPolicy, "fleet_logistics", :logistics)

        ScopedSearch::Source.new(
          type: "FleetInventoryItem",
          scope: FleetInventoryItem.where(fleet_inventory_id: visible_fleet_inventories.select(:id))
            .includes(:fleet_inventory).order(:name),
          filter: :name_cont,
          item: lambda { |item|
            ScopedSearch.result(
              type: "FleetInventoryItem", name: item.name, slug: item.id, detail: item.fleet_inventory.name
            )
          }
        )
      end

      private def readable?(policy, feature, capability)
        feature_enabled?(feature, @fleet) &&
          fleet_capability_available?(capability) &&
          allowed_to?(:index?, with: policy, context: {fleet: @fleet})
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end
    end
  end
end
