# encoding: utf-8
# frozen_string_literal: true

class RsiOrg < ApplicationRecord
  has_many :rsi_affiliations,
           -> { where(main: true) }
  has_many :users, through: :rsi_affiliations
  has_many :user_ships,
           -> { where(purchased: true) },
           through: :users

  validates :name, :sid, presence: true
end
