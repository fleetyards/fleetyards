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

      # Only fleets whose ship list the reader may open, and only when someone
      # besides the reader flies the model there. `total` is what that list
      # shows, the reader's own ships included; the owners are everyone else,
      # and those hiding themselves as owners are counted but not named.
      # Loaners are left out, as the list does.
      private def load_fleets
        @fleets = []
        return unless fleets_readable?

        fleet_ids = current_resource_owner.fleets
          .select { |fleet| allowed_to?(:index?, fleet, with: FleetVehiclePolicy) }
          .map(&:id)

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
