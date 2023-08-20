# frozen_string_literal: true

module Api
  module V1
    class ScDataController < ::Api::BaseController
      before_action :authenticate_user!, only: []

      def current_version
        authorize! :show, :api

        render json: {version: Imports::ScDataImport.current_version || "2.6.0-490789-c"}, status: :ok
      end
    end
  end
end
