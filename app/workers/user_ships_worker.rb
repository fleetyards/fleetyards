# frozen_string_literal: true

class UserShipsWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['USER_SHIPS_QUEUE'] || 'fleetyards_user_ships').to_sym

  def perform(ship_id)
    UserShip.where(ship_id: ship_id, notify: true).find_each do |user_ship|
      UserShipMailer.on_sale(user_ship).deliver_later
    end
  end
end
