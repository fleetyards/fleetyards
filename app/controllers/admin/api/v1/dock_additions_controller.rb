# frozen_string_literal: true

module Admin
  module Api
    module V1
      class DockAdditionsController < ::Admin::Api::BaseController
        before_action :set_dock_addition, only: %i[show destroy]

        def index
          authorize! with: ::Admin::DockPolicy

          @q = authorized_scope(DockAddition.includes(:model), with: ::Admin::DockPolicy)
            .ransack(dock_addition_query_params)

          @dock_additions = @q.result
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def create
          @dock_addition = DockAddition.new(dock_addition_params)

          authorize! @dock_addition, with: ::Admin::DockPolicy

          if @dock_addition.save
            render :show, status: :created
          else
            render json: ValidationError.new("dock_addition.create", errors: @dock_addition.errors),
              status: :bad_request
          end
        end

        def show
        end

        # No update: a row says "this ship fits this berth" and nothing about it
        # can change without becoming a different statement.
        def destroy
          @dock_addition.destroy

          head :no_content
        end

        private def set_dock_addition
          @dock_addition = DockAddition.find(params[:id])

          authorize! @dock_addition, with: ::Admin::DockPolicy
        end

        private def dock_addition_params
          @dock_addition_params ||= params.permit(:dock_id, :model_id)
        end

        private def dock_addition_query_params
          @dock_addition_query_params ||= params.permit(q: [
            :dock_id_eq, :model_id_eq, :sorts
          ]).fetch(:q, {})
        end
      end
    end
  end
end
