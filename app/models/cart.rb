# frozen_string_literal: true

# A named shopping list. Each user has at most one active list, which is the
# one items are added to from the catalogues.
class Cart < ApplicationRecord
  MAX_PER_USER = 25
  DEFAULT_NAME = "Shopping list"

  belongs_to :user
  has_many :cart_items, dependent: :delete_all

  validates :name, presence: true, length: {maximum: 64}, uniqueness: {scope: :user_id}
  validate :cart_limit, on: :create

  def self.active_for(user)
    user.carts.find_by(active: true)
  end

  # Adding from a catalogue before any list exists starts one, or, if every
  # list was deactivated, picks the most recent back up.
  def self.active_for!(user)
    active_for(user) || user.carts.order(updated_at: :desc).first&.tap(&:activate!) ||
      user.carts.create!(name: DEFAULT_NAME, active: true)
  rescue ActiveRecord::RecordNotUnique
    active_for(user)
  end

  def activate!
    return if active?

    transaction do
      user.carts.where(active: true).update_all(active: false)
      update!(active: true)
    end
  end

  # The active list falls to the most recently touched one left, so adding
  # from a catalogue keeps going somewhere the user can see.
  def destroy_and_reactivate!
    transaction do
      destroy!
      user.carts.order(updated_at: :desc).first&.activate! if active?
    end
  end

  private def cart_limit
    return if user.blank?
    return if user.carts.count < MAX_PER_USER

    errors.add(:base, :cart_list_limit_reached, count: MAX_PER_USER)
  end
end
