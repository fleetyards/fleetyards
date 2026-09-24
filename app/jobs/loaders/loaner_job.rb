# frozen_string_literal: true

module Loaders
  class LoanerJob < ::Loaders::BaseJob
    def perform
      missing_loaners, missing_models = ::Rsi::LoanerLoader.new.run

      model_ids = ModelLoaner.pluck(:model_id).uniq

      # `add_loaners` runs over every vehicle of every loaner-bearing model, so
      # this is the widest machine write there is against the hangar.
      PaperTrail.request(enabled: false) do
        # A pairing RSI dropped, where the loaner model is still lent by other
        # ships: the cleanup below keeps these rows, and `add_loaners` never
        # reaches a parent whose model lends nothing any more. Removed first so
        # the pass below settles which loaner of each model stays visible.
        Vehicle.where(loaner: true).where.not(vehicle_id: nil).where(<<~SQL.squish).destroy_all
          NOT EXISTS (
            SELECT 1 FROM vehicles parents
            JOIN model_loaners ON model_loaners.model_id = parents.model_id
            WHERE parents.id = vehicles.vehicle_id
              AND model_loaners.loaner_model_id = vehicles.model_id
              AND model_loaners.hidden = FALSE
          )
        SQL

        model_ids.each do |model_id|
          Vehicle.where(model_id:, loaner: false).find_each(&:add_loaners)
        end

        loaner_model_ids = ModelLoaner.pluck(:loaner_model_id).uniq

        Vehicle.where(loaner: true).where.not(model_id: loaner_model_ids).destroy_all
      end

      actionable = missing_loaners.present? || missing_models.present?

      AdminReport.deliver(
        task_type: "loaner_sync",
        # The resolve-loaners-import skill finds its issue by this title.
        title: actionable ? "Missing Loaners" : "Loaner Sync Results",
        body: missing_loaners_body(missing_loaners, missing_models),
        actionable:
      )
    end

    private def missing_loaners_body(missing_loaners, missing_models)
      return "No missing Loaners or Models found" if missing_loaners.blank? && missing_models.blank?

      lines = []

      if missing_models.present?
        lines << "## Missing Models"
        lines << ""
        missing_models.each do |model|
          lines << "- **#{model[:name]}** — Loaners: #{model[:loaners]}"
        end
      end

      if missing_loaners.present?
        lines << "" if lines.any?
        lines << "## Missing Loaners"
        lines << ""
        missing_loaners.each do |loaner|
          lines << "- **#{loaner[:loaner]}** — For Model: #{loaner[:model]} (#{loaner[:model_id]})"
        end
      end

      lines.join("\n")
    end
  end
end
