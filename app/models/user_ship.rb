class UserShip < ActiveRecord::Base
  belongs_to :ship
  belongs_to :user


  validates :ship_id, presence: true
end
