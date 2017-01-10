class UserShip < ActiveRecord::Base
  default_scope -> { order(created_at: :desc) }

  belongs_to :ship
  belongs_to :user

  validates :ship_id, presence: true

  def self.purchased
    where(purchased: true)
  end
end
