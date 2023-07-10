# frozen_string_literal: true

module Admin
  module Api
    class DocsController < ApplicationController
      def index
        authorize! :show, :admin

        @title = I18n.t("title.admin_api.docs")

        @config = {
          urls: [{
            url: "/api/v1/schema.yaml",
            name: "V1"
          }]
        }

        render "swagger_ui/index", layout: false
      end
    end
  end
end
