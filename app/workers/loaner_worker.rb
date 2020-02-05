# frozen_string_literal: true

require 'rsi/loaner_loader'

class LoanerWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['LOANER_LOADER_QUEUE'] || 'fleetyards_loaner_loader').to_sym

  def perform
    missing_loaners = ::RSI::LoanerLoader.new.run

    AdminMailer.missing_loaners(missing_loaners).deliver_later if missing_loaners.present?
  end
end
