# encoding: utf-8
# frozen_string_literal: true

require 'rsi_orgs_loader'

module Api
  module V1
    module Rsi
      class CitizensController < ::Api::V1::BaseController
        skip_authorization_check
        before_action :authenticate_api_user!, only: %i[]

        def show
          @citizen = fetch_user
        end

        private def fetch_user
          response = Typhoeus.get("https://robertsspaceindustries.com/citizens/#{handle}")
          if response.code != 200
            render json: { code: 'rsi.citizen.not_found', message: 'Could not find Citizen' }, status: :not_found
            return
          end

          parse_user(Nokogiri::HTML(response.body))
        end

        private def parse_user(page)
          user = RsiUser.new

          page.css('.info .value').each_with_index do |value, index|
            user.username = value.text.strip if index.zero?
            user.handle = value.text.strip if index == 1
            user.title = value.text.strip if index == 2
          end

          if page.css('.profile .thumb img').present?
            user.avatar = "https://robertsspaceindustries.com#{page.css('.profile .thumb img')[0]['src']}"
          end
          user.citizen_record = page.css('.citizen-record .value').text.strip

          page.css('.profile-content > .left-col .value').each_with_index do |value, index|
            if index.zero?
              user.enlisted = value.text.strip
            elsif index == 1
              user.location = value.text.strip
            elsif index == 2
              user.languages = value.text.strip
            end
          end

          user.orgs = RsiOrgsLoader.new.for_handle(handle)

          user
        end

        private def handle
          @handle ||= params[:handle].downcase
        end
      end
    end
  end
end
