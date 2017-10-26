# encoding: utf-8
# frozen_string_literal: true

require 'rsi_orgs_loader'

module Api
  module V1
    module Rsi
      class OrgsController < ::Api::V1::BaseController
        skip_authorization_check
        before_action :authenticate_api_user!, only: %i[]

        def show
          @org = RsiOrgsLoader.new.fetch(params[:sid].downcase)
        end
      end
    end
  end
end
