# frozen_string_literal: true

require 'rsi/models_loader'

class ModelsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['MODEL_LOADER_QUEUE'] || 'fleetyards_model_loader').to_sym

  def perform
    ::RSI::ModelsLoader
      .new(vat_percent: Rails.application.secrets[:rsi_vat_percent])
      .all
  end
end
