# frozen_string_literal: true

require "rsi_models_loader"

class ModelWorker
  include Sidekiq::Worker
  sidekiq_options retry: true, queue: (ENV['MODEL_LOADER_QUEUE'] || 'fleetyards_model_loader').to_sym

  def perform(model_name)
    RsiModelsLoader
      .new(vat_percent: Rails.application.secrets[:rsi_vat_percent])
      .one(model_name)
  end
end
