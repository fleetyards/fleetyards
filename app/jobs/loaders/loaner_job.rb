# frozen_string_literal: true

require "rsi/loaner_loader"

module Loaders
  class LoanerJob < ::Loaders::BaseJob
    def perform
      missing_loaners, missing_models = ::Rsi::LoanerLoader.new.run

      Vehicle.where(loaner: true, notify: true).destroy_all

      ModelLoaner.pluck(:model_id).each do |model_id|
        Vehicle.where(model_id:, loaner: false, notify: true).find_each(&:add_loaners)
      end

      AdminMailer.missing_loaners(missing_loaners, missing_models).deliver_later if missing_loaners.present? || missing_models.present?
    end
  end
end
