# frozen_string_literal: true

module Api
  module V1
    class VehiclesController < ::Api::V1::BaseController
      skip_authorization_check only: %i[public public_count]
      before_action :authenticate_api_user!, except: %i[public public_count]

      def index
        authorize! :index, :api_hangar
        @q = current_user.vehicles
                         .ransack(query_params)

        @q.sorts = ['purchased desc', 'name asc'] if @q.sorts.empty?

        @vehicles = @q.result.offset(params[:offset]).limit(params[:limit])
      end

      def count
        authorize! :index, :api_hangar
        models = current_user.models

        @count = OpenStruct.new(
          total: models.count,
          classifications: models.map(&:classification).uniq.compact.map do |classification|
            OpenStruct.new(
              count: models.where(classification: classification).count,
              name: classification,
              label: I18n.t("filter.model.classification.items.#{classification}")
            )
          end
        )
      end

      def public
        user = User.find_by!("lower(username) = ?", params.fetch(:username, '').downcase)
        @vehicles = user.vehicles
                        .purchased
                        .order(name: :asc)
                        .offset(params[:offset])
                        .limit(params[:limit])
      end

      def public_count
        user = User.find_by!("lower(username) = ?", params.fetch(:username, '').downcase)
        models = user.purchased_models

        @count = OpenStruct.new(
          total: models.count,
          classifications: models.map(&:classification).uniq.compact.map do |classification|
            OpenStruct.new(
              count: models.where(classification: classification).count,
              name: classification,
              label: I18n.t("filter.model.classification.items.#{classification}")
            )
          end
        )
      end

      def create
        @vehicle = Vehicle.new(vehicle_params)
        authorize! :create, vehicle

        if vehicle.save
          render status: :created
        else
          render json: ValidationError.new("vehicle.create", @vehicle.errors), status: :bad_request
        end
      end

      def update
        authorize! :update, vehicle

        return if vehicle.update(vehicle_params)

        render json: ValidationError.new("vehicle.update", @vehicle.errors), status: :bad_request
      end

      def destroy
        authorize! :destroy, vehicle

        return if vehicle.destroy

        render json: ValidationError.new("vehicle.destroy", @vehicle.errors), status: :bad_request
      end

      private def vehicle
        @vehicle ||= Vehicle.find_by!(id: params[:id])
      end
      helper_method :vehicle

      private def vehicle_params
        @vehicle_params ||= params.permit(:name, :model_id, :purchased, :sale_notify)
                                  .merge(
                                    user_id: current_user.id
                                  )
      end
    end
  end
end
