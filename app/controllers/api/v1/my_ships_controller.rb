# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class MyShipsController < ::Api::V1::BaseController
      def create
        @user_ship = UserShip.new(user_ship_params)
        authorize! :create, user_ship

        if user_ship.save
          ActionCable.server.broadcast("updates_hangar_#{current_user.username}", user_ship.to_builder.target!)
          render status: :created
        else
          render json: ValidationError.new("user_ship.create", @user_ship.errors), status: :bad_request
        end
      end

      def update
        authorize! :update, user_ship

        return if user_ship.update(user_ship_params)

        render json: ValidationError.new("user_ship.update", @user_ship.errors), status: :bad_request
      end

      def destroy
        authorize! :destroy, user_ship

        if user_ship.destroy
          ActionCable.server.broadcast("updates_hangar_#{current_user.username}", user_ship.to_builder.target!)
        else
          render json: ValidationError.new("user_ship.destroy", @user_ship.errors), status: :bad_request
        end
      end

      private def user_ship
        @user_ship ||= UserShip.find_by!(id: params[:id])
      end
      helper_method :user_ship

      private def user_ship_params
        @user_ship_params ||= params.permit(:name, :ship_id, :purchased, :sale_notify)
                                    .merge(
                                      user_id: current_user.id
                                    )
      end
    end
  end
end
