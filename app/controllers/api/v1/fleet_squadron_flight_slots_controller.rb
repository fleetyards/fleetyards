# frozen_string_literal: true

module Api
  module V1
    # A flight's slots, edited with the template editor's actions, and the
    # members each slot is meant for.
    class FleetSquadronFlightSlotsController < MissionSlotsController
      include FleetSquadronFlightScoped

      skip_before_action :set_slottable
      skip_before_action :set_slot

      before_action :load_flight!
      before_action :check_flight_squadrons_feature
      before_action :set_slottable, only: %i[create]
      before_action :set_slot, only: %i[update destroy]

      # The whole list in order, the first being who the slot goes to. Members
      # are named by username and must be in this squadron; a ship, when one is
      # named, has to be among those the member gives it.
      def candidates
        @slot = flight_slots.find(params[:id])
        authorize_flight!

        entries = Array(params[:candidates]).map { |entry| entry.permit(:username, :vehicle_id, :vehicleId) }
        rows = squadron_rows_by_username(entries.map { |entry| entry[:username] })

        MissionSlotCandidate.transaction do
          @slot.mission_slot_candidates.delete_all
          entries.each_with_index do |entry, index|
            row = rows[entry[:username].to_s.downcase]
            raise ActiveRecord::RecordNotFound, "member not in squadron" if row.blank?

            candidate = @slot.mission_slot_candidates.new(
              fleet_squadron_membership: row,
              vehicle_id: (entry[:vehicle_id] || entry[:vehicleId]).presence,
              position: index
            )
            candidate.errors.add(:vehicle, :not_given) unless vehicle_given?(row, candidate.vehicle_id)
            raise ActiveRecord::RecordInvalid, candidate if candidate.errors.any?

            candidate.save!
          end
        end

        @slot.mission_slot_candidates.reset
        render :show
      rescue ActiveRecord::RecordInvalid => e
        render json: ValidationError.new("fleet_squadron_flight_slots.candidates", errors: e.record.errors), status: :bad_request
      end

      private def vehicle_given?(row, vehicle_id)
        return true if vehicle_id.blank?

        FleetVehicle.where(fleet_id: @fleet.id)
          .where(vehicle_id: FleetSquadron.vehicle_ids_for(fleet_id: @fleet.id, squadron_ids: [@fleet_squadron.id])
            .where("squadron_rows.id": row.id))
          .exists?(vehicle_id:)
      end

      private def squadron_rows_by_username(usernames)
        @fleet_squadron.fleet_squadron_memberships
          .joins(fleet_membership: :user)
          .merge(FleetMembership.kept.accepted)
          .where(users: {normalized_username: usernames.compact.map { |name| name.to_s.downcase }})
          .includes(fleet_membership: :user)
          .index_by { |row| row.fleet_membership.user.normalized_username }
      end

      private def flight_slots
        team = @flight.team
        MissionSlot.where(slottable: team).or(MissionSlot.where(slottable_type: "MissionShip", slottable_id: team.mission_ships.select(:id)))
      end

      private def find_slottable(type, id)
        team = @flight.team

        case type
        when "MissionTeam" then (team.id == id) ? team : nil
        when "MissionShip" then team.mission_ships.find_by(id:)
        end
      end

      private def set_slot
        @slot = flight_slots.find(params[:id])
      end

      private def authorize_slot!(_record, _slottable, to: nil)
        authorize_flight!
      end
    end
  end
end
