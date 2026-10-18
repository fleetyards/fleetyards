# frozen_string_literal: true

module Api
  module V1
    module Public
      # A fleetyards loadout of a ship its owner shows in a public hangar, for
      # its page: the loadout, and its fitting slot by slot.
      class VehicleLoadoutsController < ::Api::PublicBaseController
        include PublicHangarOwnerConcern

        before_action :set_vehicle_loadout

        def show
        end

        def slots
          @loadout_slots = @vehicle_loadout.slots
        end

        # The same ships the public hangar lists, found by address like the
        # plaque. A linked build lives on another site, so only fleetyards
        # loadouts have a page.
        private def set_vehicle_loadout
          vehicle = @user.vehicles.purchased.public.at_address(params[:vehicle_id]).first!
          @vehicle_loadout = vehicle.vehicle_loadouts.kind_fleetyards.find(params[:id])
        end
      end
    end
  end
end
