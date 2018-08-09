# frozen_string_literal: true

require 'rsi_orgs_loader'

module Api
  module V1
    module Rsi
      class OrgsController < ::Api::V1::BaseController
        skip_authorization_check
        before_action :authenticate_api_user!, only: %i[]

        def show
          success, @org = RsiOrgsLoader.new.fetch(params[:sid].downcase)

          return if success

          render json: { code: 'rsi.org.not_found', message: 'Could not find Org' }, status: :not_found
        end
      end
    end
  end
end
