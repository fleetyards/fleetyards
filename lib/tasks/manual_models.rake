# frozen_string_literal: true

namespace :models do
  desc "Import manually curated models (ships not in the RSI ship-matrix). Idempotent, safe to re-run on live."
  task seed_manual: :environment do
    load Rails.root.join("db/seeds/01_manual_models.rb")
  end
end
