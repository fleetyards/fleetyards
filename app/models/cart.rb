# frozen_string_literal: true

# A named shopping list. Each user has at most one active list, which is the
# one items are added to from the catalogues.
class Cart < ApplicationRecord
  MAX_PER_USER = 25

  belongs_to :user
  has_many :cart_items, dependent: :delete_all

  validates :name, presence: true, length: {maximum: 64}, uniqueness: {scope: :user_id}
  validate :cart_limit, on: :create

  def self.active_for(user)
    user.carts.find_by(active: true)
  end

  # Adding from a catalogue before any list exists starts one, or, if every
  # list was deactivated, picks the most recently activated or renamed one
  # back up. Lines do not touch their list: a bulk add would then lock the
  # list behind its lines while a quantity edit locks them the other way round.
  def self.active_for!(user)
    active_for(user) || user.carts.order(updated_at: :desc).first&.tap(&:activate!) ||
      user.carts.create!(name: default_name(user), active: true)
  rescue ActiveRecord::RecordNotUnique
    active_for(user)
  end

  def self.default_name(user)
    I18n.with_locale(user.notification_locale) { I18n.t("defaults.cart.name") }
  end

  def activate!
    return if active?

    # Locked on the user, so two activations queue up instead of both
    # clearing the old one and colliding on the one-active index.
    transaction do
      user.lock!
      user.carts.where(active: true).update_all(active: false)
      update!(active: true)
    end
  end

  # The active list falls to the most recently activated or renamed one left,
  # so adding from a catalogue keeps going somewhere the user can see.
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
