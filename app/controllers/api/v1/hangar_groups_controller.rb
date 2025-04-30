# frozen_string_literal: true

module Api
  module V1
    class HangarGroupsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        except: %i[index]
      before_action :set_hangar_group, only: %i[update destroy]

      def index
        authorize!

        @groups = authorized_scope(HangarGroup.all)
          .order([{sort: :asc, name: :asc}])
          .all
      end

      def create
        @hangar_group = HangarGroup.new(hangar_group_params)

        authorize! @hangar_group

        if @hangar_group.save
          render status: :created
        else
          render json: ValidationError.new("hangar_group.create", errors: @hangar_group.errors), status: :bad_request
        end
      end

      def update
        return if @hangar_group.update(hangar_group_params)

        render json: ValidationError.new("vehicle.update", errors: @hangar_group.errors), status: :bad_request
      end

      def destroy
        return if @hangar_group.destroy

        render json: ValidationError.new("hangar_group.destroy", errors: @hangar_group.errors), status: :bad_request
      end

      def sort
        authorize! to: :index?

        sorting = params.permit(sorting: [])

        (sorting[:sorting] || []).each_with_index do |id, index|
          group = authorized_scope(HangarGroup.all).where(id:).first
          next if group.blank?

          group.update(sort: index)
        end

        render json: {success: true}
      end

      private def set_hangar_group
        @hangar_group = HangarGroup.find(params[:id])

        authorize! @hangar_group
      end

      private def hangar_group_params
        @hangar_group_params ||= params.permit(:name, :color, :sort, :public).merge(user_id: current_user.id)
      end
    end
  end
end
