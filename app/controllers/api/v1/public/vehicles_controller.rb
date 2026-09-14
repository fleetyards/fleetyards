# frozen_string_literal: true

module Api
  module V1
    module Public
      class VehiclesController < ::Api::PublicBaseController
        include HangarFiltersConcern

        # DEPRECATED
        def fleetchart
          user = User.find_by!(normalized_username: params.fetch(:username, "").downcase)

          # Was two inline `public_hangar?` checks. Visibility has a second
          # answer now, and a rule with two spellings is a rule with one of them
          # forgotten -- so this asks the policy every other hangar path asks.
          authorize! user, to: :show?, with: ::Public::UserPolicy

          @q = user.vehicles
            .visible
            .purchased
            .public
            .ransack(vehicle_query_params)

          @vehicles = Vehicle.where(
            Vehicle.arel_table[:id].in(@q.result(distinct: true).reorder(nil).select(:id).arel)
          )
            .includes(:model, :vehicle_loadouts)
            .joins(:model)
            .sort_by { |vehicle| [-vehicle.model.length, vehicle.model.name] }
        end
      end
    end
  end
end
