# frozen_string_literal: true

module Api
  module V1
    class HangarGroupsController < ::Api::BaseController
      def index
        authorize! :index, :api_hangar_groups
        @groups = HangarGroup.where(user_id: current_user.id)
          .order([{ sort: :asc, name: :asc }])
          .all
      end

      def public
        authorize! :public, :api_hangar_groups

        user = User.find_by!('lower(username) = ?', params.fetch(:username, '').downcase)

        @groups = HangarGroup.where(user_id: user.id, public: true)
          .order([{ sort: :asc, name: :asc }])
          .all
      end

      def create
        @hangar_group = HangarGroup.new(hangar_group_params)
        authorize! :create, hangar_group

        if hangar_group.save
          render status: :created
        else
          render json: ValidationError.new('hangar_group.create', @hangar_group.errors), status: :bad_request
        end
      end

      def update
        authorize! :update, hangar_group

        return if hangar_group.update(hangar_group_params)

        render json: ValidationError.new('vehicle.update', @hangar_group.errors), status: :bad_request
      end

      def destroy
        authorize! :destroy, hangar_group

        return if hangar_group.destroy

        render json: ValidationError.new('hangar_group.destroy', @hangar_group.errors), status: :bad_request
      end

      def sort
        authorize! :sort, :api_hangar_groups

        sorting = params.permit(sorting: [])

        (sorting[:sorting] || []).each_with_index do |id, index|
          group = HangarGroup.where(user_id: current_user.id, id: id).first
          next if group.blank?

          group.update(sort: index)
        end

        render json: { succees: true }
      end

      private def hangar_group
        @hangar_group ||= HangarGroup.find(params[:id])
      end
      helper_method :hangar_group

      private def hangar_group_params
        @hangar_group_params ||= params.permit(:name, :color, :sort, :public).merge(user_id: current_user.id)
      end
    end
  end
end
