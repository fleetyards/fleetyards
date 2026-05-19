# frozen_string_literal: true

module Admin
  module Api
    module V1
      class UserFleetsController < ::Admin::Api::BaseController
        before_action :set_user

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.user", slug: params[:user_id]))
        end

        def index
          @memberships = @user.fleet_memberships
            .includes(:fleet, :fleet_role)
            .order(primary: :desc, created_at: :asc)
            .page(params[:page])
            .per(per_page(FleetMembership))
        end

        private def set_user
          @user = User.find(params[:user_id])

          authorize! @user, with: ::Admin::UserPolicy
        end
      end
    end
  end
end
