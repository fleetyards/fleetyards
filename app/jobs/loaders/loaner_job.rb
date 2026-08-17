# frozen_string_literal: true

module Loaders
  class LoanerJob < ::Loaders::BaseJob
    def perform
      missing_loaners, missing_models = ::Rsi::LoanerLoader.new.run

      model_ids = ModelLoaner.pluck(:model_id).uniq

      model_ids.each do |model_id|
        Vehicle.where(model_id:, loaner: false).find_each(&:add_loaners)
      end

      loaner_model_ids = ModelLoaner.pluck(:loaner_model_id).uniq

      Vehicle.where(loaner: true).where.not(model_id: loaner_model_ids).destroy_all

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
