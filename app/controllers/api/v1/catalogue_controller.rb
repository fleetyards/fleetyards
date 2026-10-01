# frozen_string_literal: true

module Api
  module V1
    # The items a markdown text names inline, `[*Name*]` or `[*type:Name*]`.
    # What a contract, event or user token resolves to depends on who asks.
    class CatalogueController < ::Api::PublicBaseController
      FLEET_SCOPES = %w[fleet fleet:read].freeze

      skip_verify_authorized only: %i[lookup search]

      def lookup
        @matches = resolver.resolve(params[:names])

        render :matches
      end

      def search
        @matches = resolver.search(params[:q])

        render :matches
      end

      private def resolver
        ::Catalogue::TokenResolver.new(reader: current_resource_owner, fleet_reader:)
      end

      # The fleet pages refuse an OAuth token that may not read fleets, so
      # their tokens do not resolve for one either.
      private def fleet_reader
        return current_resource_owner if doorkeeper_token.blank?

        current_resource_owner if doorkeeper_token.includes_scope?(*FLEET_SCOPES)
      end
    end
  end
end
