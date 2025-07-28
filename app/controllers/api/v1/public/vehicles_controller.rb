# frozen_string_literal: true

module Api
  module V1
    module Public
      class VehiclesController < ::Api::PublicBaseController
        include HangarFiltersConcern

        # DEPRECATED
        def fleetchart
          user = User.find_by!(normalized_username: params.fetch(:username, "").downcase)

          unless user.public_hangar?
            not_found
            return
          end

          @q = user.vehicles
            .visible
            .purchased
            .public
            .ransack(vehicle_query_params)

          @vehicles = []
          return unless user.public_hangar?

          @vehicles = @q.result(distinct: true)
            .includes(:model)
            .joins(:model)
            .sort_by { |vehicle| [-vehicle.model.length, vehicle.model.name] }
        end
      end
    end
  end
end
