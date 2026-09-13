# frozen_string_literal: true

module Inventories
  # Sends home the goods of transfers nobody answered.
  #
  # Escrowed stock must not be able to sit in limbo because the far end went
  # quiet, and it cannot be put right lazily on read: the goods are *gone* from
  # the sender's inventory until something deposits them back, and nobody is
  # visiting a page that would trigger it.
  class ExpireTransfersJob < ::ApplicationJob
    sidekiq_options queue: "default", retry: 3

    def perform
      ::InventoryTransfer.pending.where(expires_at: ...Time.current).find_each do |transfer|
        resolver = TransferResolver.new(transfer)

        if resolver.expire
          TransferNotifier.new(transfer).notify_resolved
        else
          Rails.logger.warn(
            "[ExpireTransfersJob] #{transfer.id}: #{resolver.errors.full_messages.to_sentence}"
          )
        end
      end
    end
  end
end
