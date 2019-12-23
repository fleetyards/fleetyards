# frozen_string_literal: true

require 'rsi/orgs_loader'

module Api
  module V1
    module Rsi
      class CitizensController < ::Api::V1::BaseController
        skip_authorization_check
        before_action :authenticate_api_user!, only: %i[]

        def show
          success, @citizen = ::RSI::OrgsLoader.new.fetch_citizen(handle)

          return if success

          render json: { code: 'rsi.citizen.not_found', message: 'Could not find Citizen' }, status: :not_found
        end

        private def handle
          @handle ||= params[:handle].downcase
        end
      end
    end
  end
end
