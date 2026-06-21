# frozen_string_literal: true

module Patreon
  class SupporterImporter
    SOURCE_CURRENCY = "USD"
    TARGET_CURRENCY = "EUR"

    def self.call(client: Patreon::Client.new, campaign_id: default_campaign_id)
      new(client:, campaign_id:).call
    end

    def self.default_campaign_id
      Rails.application.credentials.dig(:patreon, :campaign_id)
    end

    def initialize(client:, campaign_id:)
      @client = client
      @campaign_id = campaign_id
      @stats = {created: 0, updated: 0, ended: 0, skipped: 0}
    end

    def call
      raise Patreon::Error, "missing Patreon campaign_id" if @campaign_id.blank?

      @client.members(@campaign_id).each { |member| import(member) }
      @stats
    end

    private

    def import(member)
      record = SupporterContribution.find_by(patreon_member_id: member.id)

      # Free-tier or churned members report no positive amount. Don't create a
      # row for them, but still end an existing row when they've become a former
      # patron — otherwise a previously-synced supporter would count forever.
      return end_or_skip(record, member) if member.amount_cents.to_i <= 0

      upsert(record || SupporterContribution.new(patreon_member_id: member.id), member)
    end

    def end_or_skip(record, member)
      if record.nil? || member.status != "former_patron"
        @stats[:skipped] += 1
        return
      end

      ended_now = apply_lifecycle(record, member)
      unless record.changed?
        @stats[:skipped] += 1
        return
      end

      record.save!
      @stats[:updated] += 1
      @stats[:ended] += 1 if ended_now
    end

    def upsert(record, member)
      new_record = record.new_record?

      assign_defaults(record, member) if new_record
      record.name = member.name
      apply_amount(record, member)
      ended_now = apply_lifecycle(record, member)

      return unless record.changed?

      record.save!
      @stats[new_record ? :created : :updated] += 1
      @stats[:ended] += 1 if ended_now

      Notifications::NewPatronJob.perform_async(record.id) if new_record && record.ended_at.blank?
    end

    def assign_defaults(record, member)
      record.source = "patreon"
      record.anonymous = true
      record.recurring = true
      record.started_at = member.pledged_at || Date.current
    end

    def apply_amount(record, member)
      return if record.source_amount_cents == member.amount_cents

      record.source_amount_cents = member.amount_cents
      record.source_currency = SOURCE_CURRENCY
      record.amount_cents = ExchangeRateFetcher.convert_cents(member.amount_cents, from: SOURCE_CURRENCY, to: TARGET_CURRENCY)
      record.currency = TARGET_CURRENCY
    end

    def apply_lifecycle(record, member)
      if member.status == "former_patron"
        was_active = record.ended_at.blank?
        record.ended_at = member.last_charge_date || Date.current
        was_active && record.ended_at.present?
      else
        record.ended_at = nil
        false
      end
    end
  end
end
