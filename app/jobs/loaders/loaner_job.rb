# frozen_string_literal: true

require "rsi/loaner_loader"

module Loaders
  class LoanerJob < ::Loaders::BaseJob
    def perform
      missing_loaners, missing_models, model_loaners = ::Rsi::LoanerLoader.new.run

      ModelLoaner.pluck(:model_id).each do |model_id|
        Vehicle.where(model_id:, loaner: false).find_each(&:add_loaners)
      end

      Vehicle.where(loaner: true).where.not(model_id: model_loaners).destroy_all

      AdminMailer.missing_loaners(missing_loaners, missing_models).deliver_later if missing_loaners.present? || missing_models.present?
    end
  end
end
