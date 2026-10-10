# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class SyncRsiHangarInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            items: {
              type: :array,
              items: ::V1::Schemas::Inputs::RsiHangarItemInput
            },
            hangarGroupId: {type: :string, format: :uuid},
            addBundledVehicles: {type: :boolean, default: true},
            syncPaints: {type: :boolean, default: false},
            syncHangarFlair: {type: :boolean, default: false},
            unmatchedVehiclesAction: ::V1::Schemas::Enums::HangarSyncUnmatchedActionEnum,
            unmatchedHangarGroupId: {type: :string, format: :uuid},
            extensionVersion: {type: :string, pattern: "^[0-9A-Za-z.+-]{1,32}$"},
            # Pages the parser read only in part. Their ships may be among what
            # it could not read, so the run leaves unmatched ships alone.
            unreadPages: {
              type: :array,
              maxItems: 5,
              items: ::V1::Schemas::Inputs::RsiHangarUnreadPageInput
            }
          }
        })
      end
    end
  end
end
