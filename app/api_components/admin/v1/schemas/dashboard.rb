# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      # Every figure the admin dashboard needs, in one payload.
      #
      # Nothing is required: each field is gated on the privilege that owns the
      # page behind it, so an admin without `imports` gets a response with no
      # import counts at all rather than a zero that reads as "nothing failed".
      class Dashboard
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            unlistedModelsCount: {type: :integer},
            failedImportsCount: {type: :integer},
            stuckImportsCount: {type: :integer},
            unresolvedRsiRequestLogsCount: {type: :integer},
            actionableNotificationsCount: {type: :integer},
            jobsEnqueuedCount: {type: :integer},
            jobsRetryCount: {type: :integer},
            jobsDeadCount: {type: :integer},
            onlineCount: {type: :integer},
            visitsToday: {type: :integer},
            visitsSameWeekdayLastWeek: {type: :integer},
            signupsThisWeek: {type: :integer},
            signupsLastWeek: {type: :integer},
            catalogueVersion: {type: [:string, :null]},
            catalogueLoadedAt: {type: [:string, :null], format: :"date-time"}
          },
          additionalProperties: false
        })
      end
    end
  end
end
