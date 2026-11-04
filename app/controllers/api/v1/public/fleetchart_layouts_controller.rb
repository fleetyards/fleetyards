# frozen_string_literal: true

module Api
  module V1
    module Public
      # A layout its owner shared by link, read-only. The token is the only key: a
      # layout that is not shared, or shared again under a new token, is not found.
      class FleetchartLayoutsController < ::Api::PublicBaseController
        self.resource_owner_scopes = HANGAR_READER_SCOPES

        def show
          token = params[:token].to_s
          raise ActiveRecord::RecordNotFound if token.blank?

          @fleetchart_layout = FleetchartLayout.find_by!(share_token: token)

          authorize! @fleetchart_layout, to: :shared?, with: FleetchartLayoutPolicy

          raise ActiveRecord::RecordNotFound unless Flipper.enabled?(:fleetchart_layouts, @fleetchart_layout.user)

          @vehicles = @fleetchart_layout.shared_vehicles
            .includes({model: :manufacturer}, *Vehicle::LOADOUT_PRELOADS, :launch_port_location, :user)

          visible_ids = @vehicles.map(&:id)

          @placements = @fleetchart_layout.placements.select { |placement| visible_ids.include?(placement["vehicle_id"]) }
        end
      end
    end
  end
end
