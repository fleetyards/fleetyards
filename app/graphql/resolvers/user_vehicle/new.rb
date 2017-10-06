# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module UserVehicle
    class New < Resolvers::Base
      def resolve
        user_ship = UserShip.new(ship_id: args[:vehicle_id], user_id: current_user.id)

        if user_ship.save
          ActionCable.server.broadcast("updates_hangar_#{current_user.username}", user_ship.to_builder.target!)
        else
          add_active_record_errors(user_ship)
        end

        user_ship
      end
    end
  end
end
