# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ResourceAccessCatalogController < ::Admin::Api::BaseController
        skip_verify_authorized

        def index
          @groups = AdminUser.privilege_groups
        end
      end
    end
  end
end
