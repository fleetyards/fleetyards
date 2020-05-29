# frozen_string_literal: true

require 'rsi/loaner_loader'

class LoanerWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['LOANER_LOADER_QUEUE'] || 'fleetyards_loaner_loader').to_sym

  def perform
    missing_loaners = ::RSI::LoanerLoader.new.run

    Vehicle.where(loaner: true, notify: true).destroy_all

    ModelLoaner.pluck(:model_id).each do |model_id|
      Vehicle.where(model_id: model_id, loaner: false, notify: true).find_each(&:add_loaners)
    end

    AdminMailer.missing_loaners(missing_loaners).deliver_later if missing_loaners.present?
  end
end
