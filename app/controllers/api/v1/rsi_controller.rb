# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class RsiController < ::Api::V1::BaseController
      skip_authorization_check
      before_action :authenticate_api_user!, only: %i[]

      def citizen
        @user = fetch_user
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

        user.orgs = fetch_orgs

        user
      end

      private def fetch_orgs
        response = Typhoeus.get("https://robertsspaceindustries.com/citizens/#{handle}/organizations")
        if response.code != 200
          render json: { code: 'rsi.citizen.not_found', message: 'Could not find Citizen' }, status: :not_found
          return
        end

        parse_orgs(Nokogiri::HTML(response.body))
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      private def parse_orgs(page)
        orgs = []

        page.css('.orgs-content .org').each_with_index do |org_box, index|
          org = RsiOrg.new
          org.main = index.zero?
          org_box.css('.value').each_with_index do |value, org_index|
            org.name = value.text.strip if org_index.zero?
            org.sid = value.text.strip if org_index == 1
            org.rank = value.text.strip if org_index == 2
            org.archetype = value.text.strip if org_index == 3
            org.language = value.text.strip if org_index == 4
            org.main_activity = value.text.strip if org_index == 5
            org.recruiting = value.text.strip if org_index == 6
            org.secondary_activity = value.text.strip if org_index == 7
            org.rpg = value.text.strip if org_index == 8
            org.commitment = value.text.strip if org_index == 9
            org.exclusive = value.text.strip if org_index == 10
          end
          if org_box.css('.thumb img').present?
            org.logo = "https://robertsspaceindustries.com#{org_box.css('.thumb img')[0]['src']}"
          end
          orgs << org
        end

        orgs
      end

      private def handle
        @handle ||= params[:handle].downcase
      end
    end
  end
end
