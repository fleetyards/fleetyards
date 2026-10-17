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
        # A port inside a part does not know what the slot came with; the
        # caller, holding the slot, says.
        stock = params[:stock_id].present? ? Component.find_by(id: params[:stock_id]) : hardpoint.facts.component

        # The ship it is for, whose tags a part may demand.
        model = Model.find_by(slug: params[:model_slug]) if params[:model_slug].present?
        ship_tags = LoadoutSlots.ship_tags_for(model) if model

        @options = LoadoutSlots.options(hardpoint, stock:, ship_tags:)
        @ports = Hardpoint.in_build.where(parent_type: "Component", parent_id: @options.map(&:id))
          .includes(Hardpoint::RENDERED)
          .group_by(&:parent_id)
      end
    end
  end
end
