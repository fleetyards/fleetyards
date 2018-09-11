# frozen_string_literal: true

class CleanupAuthTokensWorker
  include Sidekiq::Worker
  sidekiq_options retry: true, queue: (ENV['CLEANUP_AUTH_TOKENS_QUEUE'] || 'fleetyards_cleanup_auth_tokens').to_sym

  def perform
    AuthToken.expired.destroy_all
  end
end
