# frozen_string_literal: true

module Cleanup
  class FleetInviteUrlJob < ::Cleanup::BaseJob
    def perform
      FleetInviteUrl.find_each do |invite_url|
        next unless invite_url.expired? || invite_url.limit_reached?

        invite_url.destroy
      end
    end
  end
end
