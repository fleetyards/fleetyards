# frozen_string_literal: true

module Admin
  module Api
    module V1
      class AdminUsersController < ::Admin::Api::BaseController
        def me
          authorize! current_user, with: ::Admin::AdminUserPolicy

          @admin_user = current_user
        end
      end
    end
  end
end
