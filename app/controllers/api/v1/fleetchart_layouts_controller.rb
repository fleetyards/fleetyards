# frozen_string_literal: true

module Api
  module V1
    class FleetchartLayoutsController < ::Api::BaseController
      include FleetchartLayoutsFeatureConcern

      READ_ACTIONS = %i[index show].freeze

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: READ_ACTIONS
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        except: READ_ACTIONS

      before_action :check_fleetchart_layouts_feature
      before_action :set_fleetchart_layout, except: %i[index create]

      def index
        authorize! with: FleetchartLayoutPolicy

        @fleetchart_layouts = authorized_scope(FleetchartLayout.all, with: FleetchartLayoutPolicy)
          .order(updated_at: :desc)
      end

      def show
      end

      def create
        @fleetchart_layout = current_resource_owner.fleetchart_layouts.new(fleetchart_layout_params)

        authorize! @fleetchart_layout, with: FleetchartLayoutPolicy

        if saved_without_a_name_clash { @fleetchart_layout.save }
          render :show, status: :created
        else
          render json: ValidationError.new("fleetchart_layouts.create", errors: @fleetchart_layout.errors), status: :bad_request
        end
      end

      def update
        if saved_without_a_name_clash { @fleetchart_layout.update(fleetchart_layout_params) }
          render :show
        else
          render json: ValidationError.new("fleetchart_layouts.update", errors: @fleetchart_layout.errors), status: :bad_request
        end
      end

      def destroy
        @fleetchart_layout.destroy!

        render json: {success: true}
      end

      def share
        @fleetchart_layout.share!

        render :show
      end

      def unshare
        @fleetchart_layout.unshare!

        render :show
      end

      # Two requests can both pass the uniqueness validation, and then only the
      # database index notices.
      private def saved_without_a_name_clash
        yield
      rescue ActiveRecord::RecordNotUnique
        @fleetchart_layout.errors.add(:name, :taken)
        false
      end

      private def set_fleetchart_layout
        @fleetchart_layout = authorized_scope(FleetchartLayout.all, with: FleetchartLayoutPolicy).find(params[:id])

        authorize! @fleetchart_layout, to: :show?, with: FleetchartLayoutPolicy
      end

      private def fleetchart_layout_params
        permitted = params.permit(
          :name, :colored,
          placements: %i[vehicle_id x y facing viewpoint state order group_id heading removed],
          catalogue_placements: %i[id model_id x y facing viewpoint state order group_id heading]
        ).to_h

        permitted[:placements] = permitted[:placements].map(&:to_h) if permitted[:placements]
        permitted[:catalogue_placements] = permitted[:catalogue_placements].map(&:to_h) if permitted[:catalogue_placements]

        permitted
      end
    end
  end
end
