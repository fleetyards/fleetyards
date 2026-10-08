# frozen_string_literal: true

module Api
  module V1
    module Me
      class HangarSharesController < ::Api::BaseController
        before_action :authenticate_user!, only: []
        before_action -> { doorkeeper_authorize! "user", "user:read" },
          unless: :user_signed_in?,
          only: %i[show]
        before_action -> { doorkeeper_authorize! "user", "user:write" },
          unless: :user_signed_in?,
          only: %i[create destroy rotate]

        skip_verify_authorized only: %i[show create destroy rotate]

        before_action :set_user

        def show
          render :show
        end

        def create
          @user.ensure_hangar_share_token!
          render :show
        end

        def rotate
          @user.rotate_hangar_share_token!
          render :show
        end

        def destroy
          @user.clear_hangar_share_token!
          head :no_content
        end

        private def set_user
          @user = current_resource_owner
        end
      end
    end
  end
end
