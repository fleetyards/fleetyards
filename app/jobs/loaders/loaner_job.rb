# frozen_string_literal: true

module Loaders
  class LoanerJob < ::Loaders::BaseJob
    def perform
      # Serialize per task so a clean run's resolve can't close an issue a concurrent
      # problematic run just opened. Both recompute their results while holding the lock.
      ApplicationRecord.with_advisory_lock("loaders:loaner_sync") do
        result = ::Rsi::LoanerLoader.new.run
        missing_loaners, missing_models = result

        model_ids = ModelLoaner.pluck(:model_id).uniq

        model_ids.each do |model_id|
          Vehicle.where(model_id:, loaner: false).find_each(&:add_loaners)
        end

        loaner_model_ids = ModelLoaner.pluck(:loaner_model_id).uniq

        Vehicle.where(loaner: true).where.not(model_id: loaner_model_ids).destroy_all

        creator = GithubIssueCreator.new(
          task_type: "loaner_sync",
          title: "Missing Loaners",
          body: missing_loaners_body(missing_loaners, missing_models)
        )

        if missing_loaners.present? || missing_models.present?
          creator.run
        elsif result
          # Only resolve on a genuine clean result; a nil result means the RSI fetch failed,
          # so leave any open issue untouched rather than closing a still-live failure.
          creator.resolve
        end
      end
    end

    private def missing_loaners_body(missing_loaners, missing_models)
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
