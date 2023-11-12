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

      AdminMailer.missing_loaners(missing_loaners, missing_models).deliver_later if missing_loaners.present? || missing_models.present?
    end
  end
end
