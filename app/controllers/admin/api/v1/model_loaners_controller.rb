# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelLoanersController < ::Admin::Api::BaseController
        before_action :set_model_loaner, only: %i[show update destroy]

        def index
          authorize! with: ::Admin::ModelLoanerPolicy

          @q = authorized_scope(ModelLoaner.includes(:model, :loaner_model)).ransack(loaner_query_params)

          @model_loaners = @q.result
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def create
          @model_loaner = ModelLoaner.new(loaner_params)

          authorize! @model_loaner, with: ::Admin::ModelLoanerPolicy

          if @model_loaner.save
            render :show, status: :created
          else
            render json: ValidationError.new("model_loaner.create", errors: @model_loaner.errors), status: :bad_request
          end
        end

        def show
        end

        def update
          if @model_loaner.update(loaner_params)
            render :show, status: :ok
          else
            render json: ValidationError.new("model_loaner.update", errors: @model_loaner.errors), status: :bad_request
          end
        end

        def destroy
          @model_loaner.destroy

          head :no_content
        end

        private def set_model_loaner
          @model_loaner = ModelLoaner.find(params[:id])

          authorize! @model_loaner, with: ::Admin::ModelLoanerPolicy
        end

        private def loaner_params
          @loaner_params ||= params.permit(
            :model_id, :loaner_model_id, :hidden
          )
        end

        private def loaner_query_params
          @loaner_query_params ||= params.permit(q: [
            :model_id_eq, :loaner_model_id_eq, :hidden_eq, :sorts
          ]).fetch(:q, {})
        end
      end
    end
  end
end
