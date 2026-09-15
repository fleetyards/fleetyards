# frozen_string_literal: true

module Kofi
  # Turns one Ko-fi webhook payload into a contribution.
  #
  # Every payment is recorded as a **non-recurring** contribution dated to the
  # day it arrived, including a subscription payment. Ko-fi notifies on payment
  # and never on cancellation, so a `recurring` row would have no event that
  # could ever end it and would grant its supporter perks forever. A monthly
  # subscriber instead produces one row per month, and
  # `SupporterContribution.active_in` counts a non-recurring row only in the
  # month it was paid -- so lapsing is automatic and needs no second signal.
  class PaymentImporter
    TARGET_CURRENCY = "EUR"

    def self.call(payload)
      new(payload).call
    end

    def initialize(payload)
      @payload = payload
    end

    # Returns the contribution, or nil for a payload carrying no money -- a
    # zero-amount event is not a donation and must not become one.
    def call
      return if transaction_id.blank?
      return if source_amount_cents <= 0

      record = SupporterContribution.find_or_initialize_by(kofi_transaction_id: transaction_id)
      assign(record)
      record.save!

      ::Supporters::Linker.call(record)

      record
    end

    private def assign(record)
      record.source = "kofi"
      record.name = @payload["from_name"].presence
      record.payer_email = @payload["email"].presence
      # The donor's own text, kept because it is where a claim key travels --
      # re-readable later, so a re-run finds a key the first pass could not
      # resolve to an account yet.
      record.note = @payload["message"].presence
      record.recurring = false
      record.started_at = paid_on
      # Ko-fi asks the donor whether the payment may be shown publicly, so
      # unlike the Patreon import this does not have to assume anonymity.
      record.anonymous = @payload["is_public"].to_s != "true"
      apply_amount(record)
    end

    private def apply_amount(record)
      record.source_amount_cents = source_amount_cents
      record.source_currency = source_currency
      record.currency = TARGET_CURRENCY
      record.amount_cents =
        if source_currency == TARGET_CURRENCY
          source_amount_cents
        else
          ExchangeRateFetcher.convert_cents(source_amount_cents, from: source_currency, to: TARGET_CURRENCY)
        end
    end

    private def transaction_id
      @payload["kofi_transaction_id"].presence
    end

    private def source_currency
      @payload["currency"].presence || TARGET_CURRENCY
    end

    private def source_amount_cents
      @source_amount_cents ||= (BigDecimal(@payload["amount"].to_s) * 100).round
    rescue ArgumentError, TypeError
      @source_amount_cents = 0
    end

    private def paid_on
      Time.zone.parse(@payload["timestamp"].to_s)&.to_date || Date.current
    rescue ArgumentError
      Date.current
    end
  end
end
