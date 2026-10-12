# frozen_string_literal: true

module Api
  module V1
    # Who in the reader's circle flies a model: their own ships of it, the
    # friends whose hangars show one, and per fleet how many are listed there.
    class ModelOwnersController < ::Api::BaseController
      include VehicleOverviewFeatureConcern
      include ModelSlugLookup

      FRIENDS_LIMIT = 12
      FLEET_MEMBERS_LIMIT = 8

      # What FleetVehiclePolicy#index? asks of a member to show the fleet's ships.
      FLEET_VEHICLES_PRIVILEGES = ["fleet:manage", "fleet:vehicles:manage", "fleet:vehicles:read"].freeze

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: -> { warden.authenticate?(scope: :user) }
      before_action :check_vehicle_overview_feature

      def index
        authorize! with: ModelOwnersPolicy

        @model = find_model_by_slug!
        return if performed?

        @vehicles = current_resource_owner.vehicles.visible.purchased
          .where(model: @model)
          .includes({image_attachment: :blob}, model_paint: ModelPaint.attachment_preloads)
          .order(:rank)

        load_friends
        load_fleets
      end

      # A token the reader granted only hangar access to has no say over their
      # fleets.
      private def fleets_readable?
        doorkeeper_token.blank? || doorkeeper_token.acceptable?(%w[fleet fleet:read])
      end

      # Friends only as far as their hangar is open to the reader, and only the
      # ships that hangar shows: bought, public and not hidden.
      private def load_friends
        friends = current_resource_owner.friends.with_hangar_readable_by(current_resource_owner)

        counts = Vehicle.visible.purchased.public
          .where(model: @model, user_id: friends.select(:id))
          .group(:user_id)
          .count

        @friends_total = counts.size

        users = ::User.where(id: counts.keys).with_attached_avatar.index_by(&:id)
        @friends = counts
          .sort_by { |user_id, count| [-count, users[user_id].username.downcase] }
          .first(FRIENDS_LIMIT)
          .map { |user_id, count| [users[user_id], count] }
      end

      # What each fleet's own ship list shows of the model: its listed ships,
      # loaners left out as that list does. Members who hide themselves as
      # owners are counted but not named. The reader's own ships are already
      # listed above, so a fleet only shows when someone else flies the model.
      private def load_fleets
        @fleets = []
        return unless fleets_readable?

        fleet_ids = current_resource_owner.kept_fleet_memberships.accepted.includes(:fleet_role)
          .select { |membership| membership.has_access?(FLEET_VEHICLES_PRIVILEGES) }
          .map(&:fleet_id)

        listed = FleetVehicle.joins(:vehicle)
          .where(fleet_id: fleet_ids, vehicles: {model_id: @model.id, loaner: false})
        totals = listed.group(:fleet_id).count

        owners = listed.joins(vehicle: :user)
          .where.not(vehicles: {user_id: current_resource_owner.id})
          .distinct
          .pluck(:fleet_id, "users.username", "users.hide_owner")
          .group_by(&:first)

        @fleets = Fleet.kept.where(id: owners.keys).with_attached_logo.order(:name).map do |fleet|
          fleet_owners = owners[fleet.id]
          named = fleet_owners.reject(&:third).map(&:second).sort_by(&:downcase)

          {
            fleet:,
            total: totals[fleet.id],
            owners_total: fleet_owners.size,
            members: named.first(FLEET_MEMBERS_LIMIT)
          }
        end
      end
    end
  end
end
