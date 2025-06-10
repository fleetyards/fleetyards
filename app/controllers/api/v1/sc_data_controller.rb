# frozen_string_literal: true

module Api
  module V1
    class ScDataController < ::Api::BaseController
      skip_verify_authorized

      before_action :authenticate_user!, only: []

      def current_version
        render json: {version: Imports::ScData::AllImport.current_version}, status: :ok
      end
    end
  end
end
