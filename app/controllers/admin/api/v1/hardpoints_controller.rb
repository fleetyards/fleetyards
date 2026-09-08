# frozen_string_literal: true

module Admin
  module Api
    module V1
      # The live `hardpoints` table, which the admin had no view of at all: the
      # page it used to have edited `model_hardpoints`, the predecessor table no
      # load had written since 2024, and that went with the legacy tables in
      # #4772.
      #
      # Read for both halves, write for the curated one only -- see
      # `Admin::HardpointPolicy` for why. A created slot is always `ship_matrix`
      # rather than taking the source from the request, so there is no way to
      # ask for a game-files row the next load would rewrite.
      class HardpointsController < ::Admin::Api::BaseController
        before_action :set_hardpoint, only: %i[show update destroy]

        # Top-level slots only. The nested ones come with their parent, through
        # the `loadouts` array the view renders, because a loadout is a tree and
        # a flat page of it reads as noise.
        def index
          authorize! with: ::Admin::HardpointPolicy

          hardpoint_query_params["sorts"] ||= "sc_name asc"

          @q = authorized_scope(Hardpoint.where.not(parent_type: "Hardpoint"))
            .ransack(hardpoint_query_params)

          @hardpoints = @q.result
            .includes(:component, hardpoints: :component)
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def show
        end

        def create
          @hardpoint = Hardpoint.new(hardpoint_params.merge(source: :ship_matrix))

          authorize! @hardpoint, with: ::Admin::HardpointPolicy

          if @hardpoint.save
            render :show, status: :created
          else
            render json: ValidationError.new("hardpoint.create", errors: @hardpoint.errors),
              status: :bad_request
          end
        end

        def update
          if @hardpoint.update(hardpoint_params)
            render :show, status: :ok
          else
            render json: ValidationError.new("hardpoint.update", errors: @hardpoint.errors),
              status: :bad_request
          end
        end

        def destroy
          @hardpoint.destroy

          head :no_content
        end

        private def set_hardpoint
          @hardpoint = Hardpoint.find(params[:id])

          authorize! @hardpoint, with: ::Admin::HardpointPolicy
        end

        # `source` is not permitted: `create` forces the curated half and an
        # update must not move a slot between owners.
        private def hardpoint_params
          @hardpoint_params ||= params.permit(
            :parent_id, :parent_type, :sc_name, :component_id, :group, :category,
            :min_size, :max_size, :details
          )
        end

        private def hardpoint_query_params
          @hardpoint_query_params ||= params.permit(q: [
            :parent_id_eq, :parent_type_eq, :source_eq, :group_eq, :category_eq,
            :component_id_eq, :sc_name_cont, :sorts
          ]).fetch(:q, {})
        end
      end
    end
  end
end
