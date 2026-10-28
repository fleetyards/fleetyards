# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating raffles_won scenario test data..."

Flipper.add(:raffles) unless Flipper.exist?(:raffles)
Flipper.enable(:raffles)

winner = FactoryBot.create(:user, username: "winner", password: "password")

won = FactoryBot.create(:raffle, :closed, title: "Won Raffle", code: "E2E-GIFT-CODE", drawn_at: 1.hour.ago)
FactoryBot.create(:raffle_entry, :after_close, raffle: won, user: winner,
  draw_position: 1, won_at: 1.hour.ago, claim_deadline_at: 2.days.from_now)

Rails.logger.info "E2E: Created raffles_won scenario test data"
