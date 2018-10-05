# frozen_string_literal: true

module Api
  module V1
    class FleetsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: %i[my create models count]
      after_action -> { pagination_header(:fleets) }, only: [:index]
      after_action -> { pagination_header(:models) }, only: [:models]

      def index
        authorize! :index, :api_fleets

        scope = Fleet
        if current_user.present? && current_user.rsi_verified?
          scope = scope.where.not(sid: current_user.rsi_orgs.map(&:downcase))
        end

        @fleets = scope.order(name: :asc)
                       .page(params[:page])
                       .per(per_page(Fleet))
      end

      def my
        authorize! :my, :api_fleets

        @fleets = if current_user.rsi_verified?
                    Fleet.where(sid: current_user.rsi_orgs.map(&:downcase)).order(name: :asc).all
                  else
                    []
                  end
      end

      def show
        authorize! :show, :api_fleets

        @fleet = Fleet.find_by!(sid: params[:sid])
      end

      def create
        authorize! :create, :api_fleets

        @fleet = Fleet.new(sid: params[:sid])
        return if @fleet.save

        render json: ValidationError.new('fleet.create', @fleet.errors), status: :bad_request
      end

      def models
        authorize! :models, fleet
        @q = fleet_models.ransack(query_params)

        @q.sorts = 'name asc' if @q.sorts.empty?

        @models = @q.result
                    .page(params[:page])
                    .per(params[:per_page] || 18)
      end

      def count
        authorize! :count, fleet

        grouped_vehicles = {}
        fleet_vehicles.includes(:model).order('models.slug asc').group_by(&:model_id).each do |_model_id, vehicles|
          grouped_vehicles[vehicles.first.model.slug] = vehicles.count
        end

        @count = OpenStruct.new(
          total: fleet_vehicles.count,
          classifications: fleet_models.map(&:classification).uniq.compact.map do |classification|
            OpenStruct.new(
              count: fleet_models.where(classification: classification).count,
              name: classification,
              label: classification.humanize
            )
          end,
          models: grouped_vehicles
        )
      end

      private def fleet
        return unless current_user.rsi_verified?
        @fleet = Fleet.where(sid: current_user.rsi_orgs.map(&:downcase)).find_by(sid: params[:sid])
      end

      private def fleet_vehicles
        @fleet_vehicles ||= begin
          member_ids = User.where(rsi_verified: true).where('lower(rsi_orgs) like ?', "% #{fleet&.sid}\n%").map(&:id)
          Vehicle.where(user_id: member_ids)
        end
      end

      private def fleet_models
        @fleet_models ||= begin
          model_slugs = fleet_vehicles.map { |vehicle| vehicle.model.slug }
          Model.where(slug: model_slugs)
        end
      end
    end
  end
end
