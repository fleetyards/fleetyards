# frozen_string_literal: true

module Api
  module V1
    class HardpointsController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[loadout_options]

      # Any port a loadout slot names by `hardpointId`: on a hull, on a module,
      # or on a component. Each option carries the ports it brings, read in one
      # query rather than one per candidate.
      def loadout_options
        hardpoint = Hardpoint.find(params[:id])

        @options = LoadoutSlots.options(hardpoint)
        @ports = Hardpoint.in_build.where(parent_type: "Component", parent_id: @options.map(&:id))
          .includes(Hardpoint::RENDERED)
          .group_by(&:parent_id)
      end
    end
  end
end
