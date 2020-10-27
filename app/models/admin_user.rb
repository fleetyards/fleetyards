# frozen_string_literal: true

class AdminUser < ApplicationRecord
  devise :database_authenticatable, :async, :recoverable, :trackable, :validatable,
         :timeoutable, :rememberable,
         authentication_keys: [:username]
end
