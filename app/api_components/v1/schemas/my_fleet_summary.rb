# frozen_string_literal: true

module V1
  module Schemas
    # A fleet as the reader's dashboard shows it. The counts are absent, not
    # zero, for a member whose role could not act on them.
    class MyFleetSummary
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          slug: {type: :string},
          logo: ::Shared::V1::Schemas::MediaFile,
          roleName: {type: :string},
          primary: {type: :boolean},
          memberCount: {type: :integer},
          onlineCount: {type: :integer},
          latestAnnouncement: ::V1::Schemas::MyFleetAnnouncementExcerpt,
          pendingJoinRequestsCount: {type: :integer},
          pendingTransfersCount: {type: :integer}
        },
        additionalProperties: false,
        required: %w[id name slug primary memberCount]
      })
    end
  end
end
